#!/usr/bin/perl

use strict;

my ($etm, $csv, $out, @lines, $line, $isComment);

$file = shift;
$isComment = "";

open(DATAIN, $etm) || die "Could not open file $file ($!)";
@lines = <DATAIN>;
close(DATAIN);




# External Table Metafile Processing Engine

$version = "External Table Metafile Processing Engine v1.4";

#  History
#  v1.0 dc    2005-04-13  Initial Version - Basic Functionality
#  v1.1 ar    2007-06-07  Added functionality for the prompts function to validate TTS prompts.
#  v1.2 ar    2007-12-06  Added empty() to check for NULL in the cell 
#  v1.3 dec   2009-05-07  Added four new attributes: name, desc, confidential, encrypted
#  v1.4 dec   2010-07-29  Bug fix: crashes when using -l and newline in row
#  v1.4.1 ck  2011-10-13  Mod to Perl (Only .etm to .csv checking
 
# Usage: cscript /nologo etmProcessor.js [-?] [-v] [-l] [-e n] [-f] [-q] -m metafile.etm -i table.csv
# -?: Show Help & Version Info (this)
# -v: Produce verbose output
# -l: Disable strict column count processing
# -e n: Allow up to n errors before exiting (default: 0)
# -f: Output to .ok or .err file (based on input table file name)
# -m metafile: Path to metafile
# -i tablefile: Path to input table file
# -q: strip surrounding quotation marks


$argv = WScript.Arguments;
$argc = argv.length;
$debug = 0;
$help = 0;
$enhance = 0;

$$etm = "";
$tablefile = "";
$strict = 1;
$errorsAllowed = 0;
$stripQuotes = 0;

$outputToFile = 0;
$outputFile = null;
$tempOutputFile = "";

$metadata;

$usage = "Usage: etmProcessor.js [-?] [-v] [-l] [-e n] [-f] [-q] -m metafile.etm -i table.csv";

for ($i = 0; i < argc; i++)
{
   $arg = argv(i);
   if (arg == "-v")
   {
      debug++;
   }
   else if (arg == "-m")
   {
      $etm = argv(i + 1);
      i++;
   }
   else if (arg == "-i")
   {
      tablefile = argv(i + 1);
      i++;
   }
   else if (arg == "-?")
   {
      help++;
   }
   else if (arg == "-l")
   {
      strict = 0;
   }
   else if (arg == "-e")
   {
      errorsAllowed = new Number(argv(i + 1));
      i++;
   }
   else if (arg == "-f")
   {
      outputToFile++;
   }
   else if (arg == "-q")
   {
      stripQuotes++;
   }
   else
   {
      print("Invalid Argument " + arg);
      print(usage);
      exit(1);
   }
}

if (help > 0)
{
   print(version);
   print(usage);
   print("\t-?: Show Help & Version Info (this)");
   print("\t-v: Produce verbose output");
   print("\t-l: Disable strict column count processing");
   print("\t-e n: Allow up to n errors before exiting (default: 0)");
   print("\t-f: Output to .ok or .err file (based on input table file name)");
   print("\t-q: Strip quotation marks from around cell values before validating");
   print("\t-m metafile: Path to metafile");
   print("\t-i tablefile: Path to input table file");
   exit(1);
}

if (debug > 0)
{
   print(version);
}

if ($etm == "" || tablefile == "")
{
   print(usage);
   exit(1);
}

print("Loading metadata from " + $etm);

# load the metadata 
metadata = loadMetaFile($etm);
if (metadata == null)
{
   print("Error Loading Metadata");
   exit(1);
}
else
{
   print("Metadata loaded");
}

# load default metadata for cells we don't have 
# note that there is no column 0 
for ($i = 1; i < metadata.length; i++)
{
   if (metadata[i] == null)
   {
      if (debug)
      {
         print("Loading default metadata for column " + i + " (" + i + ",Column " + i + ",noop())");
      }
      
      $meta = new Object();
      meta.columnIndex = i;
      meta.description = "Column " + i;
      if (strict)
      {
         meta.expression = "fail()";
      }
      else
      {
         meta.expression = "noop()";
      }
      meta.errorText = "No Metadata Provided";

	  if (enhance > 0)
	  {
		meta.metafileLine = meta.columnIndex + "," + meta.description + ",000,Default,N,N," + meta.expression + "," + meta.errorText;
	  }
	  else
	  {
		meta.metafileLine = meta.columnIndex + "," + meta.description + "," + meta.expression + "," + meta.errorText;
	  }
      
      metadata[i] = meta;
   }
}

if (enhance == 0)
{
	print("Not using ETM v1.3 enhancements");
}

$startTime = new Date();

print("Validating " + tablefile);

$errors = validateTableFile(metadata, tablefile, strict, errorsAllowed);

$endTime = new Date();
$delta = (endTime.getTime() - startTime.getTime()) / 1000;

print("Validation finished in " + delta + " seconds on " + endTime.toLocaleString());

if (errors > 0)
{
   print("Table Validation Failed: " + errors + " Errors Found");
}
else
{
   print("Table Validation Complete: No Errors Found");
}

exit(errors);


# internal functions 
function loadMetaFile(filename)
{
   $fso = new ActiveXObject("Scripting.FileSystemObject");
   $errors = 0;
   $metadata = new Array();
   
   if (fso.FileExists(filename))
   {
      $file = fso.GetFile(filename);
      $stream = file.OpenAsTextStream(1);
      
      $lineNum = 0;
      
      if (debug)
      {
         print("Loading metafile " + filename);
      }
      
      while (!stream.AtEndOfStream)
      {
         $line = stream.ReadLine();
         lineNum++;
         
         if (debug)
         {
            print(lineNum + ": " + line);
         }
         
         if (/^\s*$/.test(line))
         {
            if (debug)
            {
               print(lineNum + ": Blank");
            }
         }
         else if (/^comment/i.test(line))
         {
            if (debug)
            {
               print(lineNum + ": Comment");
            }

			# set metafile enhancements to on if found
			if (line.indexOf('etm enhanced') > 0)
			{
				print("ETM v1.3 enhancements supported");
				enhance++;
			}
         }
         else
         {
            $linemeta = parseMetaLine(line, lineNum);
            if (linemeta != null)
            {
               if (metadata[linemeta.columnIndex] == null)
               {
                  metadata[linemeta.columnIndex] = linemeta;
               }
               else
               {
                  errors++;
                  print(lineNum + ": Parse Error- Column already defined");
               }
            }
            else
            {
               errors++;
            }
         }
      }
      
      stream.Close();
      
      if (debug)
      {
         print("Metafile loaded.");
      }
   }
   else
   {
      print(filename + ": No File Found");
      errors = 1;
   }
   
   return (errors > 0 ? null : metadata);
}

function parseMetaLine(line, lineNum)
{
   $colIdx;
   $desc;
   $expr;
   $colName;
   $confidential;
   $encrypted;
   $errTxt;
   if (debug)
   {
      print(lineNum + ": Parsing \"" + line + "\"");
   }
   
   # col,desc,name,conf,enc,expr,err txt
   # err txt may contain commas
   
   $startIdx = 0;
   $endIdx = line.indexOf(",", startIdx);
   if (endIdx < 0)
   {
      print(lineNum + ": Parse Error- Too Few Fields (1)"); 
      return null;
   }
   else if (endIdx == 0)
   {
      print(lineNum + ": Parse Error- No Column Index Found");
      return null;
   }

   colIdx = line.substring(startIdx, endIdx);
   if (/\d+/.test(colIdx) == 0)
   {
      print(lineNum + ": Parse Error- Column Index is not numeric");
      printHighlightedError(lineNum, line, startIdx, endIdx);
      return null;
   }
   colIdx = new Number(colIdx);
   if (colIdx <= 0)
   {
      print(lineNum + ": Parse Error- Column Index is not positive");
      printHighlightedError(lineNum, line, startIdx, endIdx);
      return null;
   }
   if (debug)
   {
      print(lineNum + ": Found Column Index \"" + colIdx + "\"");
   }
   
   startIdx = endIdx + 1;
   endIdx = line.indexOf(",", startIdx);
   if (endIdx < 0)
   {
      print(lineNum + ": Parse Error- Too Few Fields (2)"); 
      return null;
   }
   
   desc = line.substring(startIdx, endIdx);
   if (debug)
   {
      print(lineNum + ": Found Description \"" + desc + "\"");
   }

   # only do if enhancements supported 
   if (enhance > 0)
   {
	   # name column 
	   startIdx = endIdx + 1;
	   endIdx = line.indexOf(",", startIdx);

	   if (endIdx < 0)
	   {
		   print(lineNum + ": Parse Error- Too Few Fields (3)");
		   return null;
	   }

	   colName = line.substring(startIdx, endIdx);
	   colName = trim(colName, " ");

	   if (((endIdx-startIdx) < 3) || ((/\d\d\d/.test(colName)) == 0))
	   {
		   print(lineNum + ": Parse Error- Column Name Must Be Three Digits");
		   return null;
	   }

	   if (debug)
	   {
		   print(lineNum + ": Found Column Name \"" + colName + "\"");
	   }

	   # confidential column 
	   startIdx = endIdx +1;
	   endIdx = line.indexOf(",", startIdx);

	   if (endIdx < 0)
	   {
		   print(lineNum + ": Parse Error- Too Few Fields (5)");
		   return null;
	   }

	   confidential = line.substring(startIdx, endIdx);
	   confidential = trim(confidential, " ");

	   if (((endIdx-startIdx) < 1) || ((/[YyNn]/.test(confidential)) == 0))
	   {
		   print(lineNum + ": Parse Error- Confidential Flag Required (Y/N)");
		   return null;
	   }

	   if (debug)
	   {
		   print(lineNum + ": Found Confidential Flag \"" + confidential + "\"");
	   }

	   # encrypted column 
	   startIdx = endIdx + 1;
	   endIdx = line.indexOf(",", startIdx);

	   if (endIdx < 0)
	   {
		   print(lineNum + ": Parse Error- Too Few Fields (6)");
		   return null;
	   }

	   encrypted = line.substring(startIdx, endIdx);
	   encrypted = trim(encrypted, " ");

	   if (((endIdx-startIdx) < 1) || ((/[YyNn]/.test(encrypted)) == 0))
	   {
		   print(lineNum + ": Parse Error- Encrypted Flag Required (Y/N)");
		   return null;
	   }

	   if (debug)
	   {
			print(lineNum + ": Found Encrypted Flag \"" + encrypted + "\"");
	   }
   }
   
   # look for balanced parens, ignoring contents (for now) 
   # once we find no more, then look for comma 
   # note that this does mean that we can't have a paren as an argument... oh well 
   startIdx = endIdx + 1;
   endIdx = line.indexOf("(", startIdx);
   $exprStart = startIdx;

   while (endIdx >= 0)
   {
      startIdx = endIdx + 1;
      endIdx = line.indexOf(")", startIdx);
      #print(endIdx + " = line.indexOf(\")\"," + startIdx + ");");
      if (endIdx < 0)
      {
         print(lineNum + ": Parse Error- Unbalanced parenthesis");
         printHighlightedError(lineNum, line, startIdx - 1, startIdx - 1);
         return null;
      }

      startIdx = endIdx + 1;

      $commaIdx = line.indexOf(",", startIdx);      
      $parenIdx = line.indexOf("(", startIdx);
      
      # or if we hit a comma before we hit a parenthesis, end this madness 
      if (commaIdx >= 0 && commaIdx < parenIdx)
      {
         endIdx = -1;
      }
      else
      {
         endIdx = parenIdx;
      }
   }

   # get optional last column, comments 
   endIdx = line.indexOf(",", startIdx);
   if (endIdx < 0)
   {
      # last column is optional 
      endIdx = line.length;
   }
   
   expr = line.substring(exprStart, endIdx);
   
   if (debug)
   {
      print(lineNum + ": Found Expression \"" + expr + "\"");
   }
   
   errTxt = line.substring(endIdx + 1);
         
   if (debug)
   {
      print(lineNum + ": Found Error Text \"" + errTxt + "\"");
   }
   
   # expand any m-n in expr to m,m+1,m+2,...,n 
   $expansions = expr.match(/[(,]\s*\d+\s*-\s*\d+\s*[,)]/g);
   if (expansions != null && expansions.length > 0)
   {
      for ($i = 0; i < expansions.length; i++)
      {
         $match = expansions[i];
         $matchStart = (match.charAt(0) == "," ? "," : "(");
         $matchEnd = (match.charAt(match.length - 1) == "," ? "," : ")");
         match = match.substring(1, match.length - 1);
         $idx = expr.indexOf(match);
         $pre = expr.substring(0, idx);
         $post = expr.substring(idx + match.length);
         if (debug)
         {
            print(lineNum + ": Expanding range in expression \"" + match + "\"");
            printHighlightedError(lineNum, pre + match + post, idx, idx + match.length - 1);
         }
         
         $endpoints = match.match(/\d+/g);
         endpoints[0] = new Number(endpoints[0]);
         endpoints[1] = new Number(endpoints[1]);
         match = "";
         for ($j = endpoints[0]; j <= endpoints[1]; j++)
         {
            match += j;
            if (j < endpoints[1])
            {
               match += ",";
            }
         }
         expr = pre + match + post;
      }
      if (debug)
      {
         print(lineNum + ": Expanded expression is \"" + expr + "\"");
      }
   }

   $meta = new Object();
   meta.columnIndex = colIdx;
   meta.description = desc;
   meta.expression = expr;
   meta.errorText = errTxt;
   meta.metafileLine = line;
   
   if (debug)
   {
      print(lineNum + ": Parse Complete.");
   }
   return meta;
}

function validateTableFile(metadata, filename, strict, errorsAllowed)
{
   # here's where the fun begins... 
   
   # 1) load the csv file row by row
   # 2) For each row, split to cells
   # 3) Load column data into value array:
   #    cells[] = array with value of cells (strings)
   # 4) For each column:
   #    a) Load variables
   #       currentCell = index of column
   #       currentCellValue = value of column
   #    b) Eval() the expression
   #    c) If it evals() false, then print error text and fail file.
    
  
   $fso = new ActiveXObject("Scripting.FileSystemObject");
   $errors = 0;
   
   if (fso.FileExists(filename))
   {
      $file = fso.GetFile(filename);
      $stream = file.OpenAsTextStream(1);
      
      $lineNum = 0;
      $dataLineCount = 0;
      
      if (debug)
      {
         print("Processing Table " + filename);
      }
      
      while (!stream.AtEndOfStream && errors <= errorsAllowed)
      {
         $line = stream.ReadLine();
         lineNum++;
         
         if (debug)
         {
            print(lineNum + ": " + line);
         }
         
         if (/^\s*$/.test(line))
         {
            if (debug)
            {
               print(lineNum + ": Blank");
            }
         }
         else if (/^;/.test(line))
         {
            if (debug)
            {
               print(lineNum + ": Comment");
            }
         }
         else
         {
            $lineErrs = validateLine(metadata, line, lineNum, strict);
            
            if (lineErrs)
            {
               errors += lineErrs;
            }
            else
            {
               dataLineCount++;
            }              
            
            if (debug)
            {
               if (lineErrs)
               {
                  print(lineNum + ": Line Failed Validation");
               }
               else
               {
                  print(lineNum + ": Line Passed Validation");
               }
            }
         }
      }
      
      if (!stream.AtEndOfStream && errors > errorsAllowed)
      {
         print("Table Processing Terminated: Too Many Errors");
      }
      else if (debug)
      {
         print("Table Processing Complete.");
      }
      
      while (!stream.AtEndOfStream)
      {
         $line = stream.ReadLine();
         lineNum++;
      }         

      stream.Close();
      
      print("Validated " + dataLineCount + " lines (" + lineNum + " lines in file)");      
   }
   else
   {
      print(filename + ": No File Found");
      errors = 1;
   }
   
   return errors;
}

function charCount(str, charToCount)
{
   $i;
   $count = 0;
   
   i = str.indexOf(charToCount);
   while (i >= 0)
   {
      count++;
      i = str.indexOf(charToCount, i + 1);
   }
   return count;
}

# these are global to be seen from validation routines 

function validateLine(metadata, line, lineNum, strict)
{
   $errors = 0;
   $lineOffset = 0;
   $origCells;

   origCells = line.split(",");
   cells = new Array();
   
   $quoteChar = "";
   
   for ($cell = 0; cell < origCells.length; cell++)
   {
      if (quoteChar != "")
      {
         cells.push(cells.pop() + "," + origCells[cell]);
         if (charCount(origCells[cell], quoteChar) % 2 == 1)
         {
            quoteChar = "";
         }
      }
      else if (charCount(origCells[cell], "\"") % 2 == 1)
      {
         cells.push(origCells[cell]);
         quoteChar = "\"";
      }
      else
      {
         cells.push(origCells[cell]);
      }
   }
   
   origCells = new Array();
   
   if (stripQuotes > 0)
   {
      for ($cell = 0; cell < cells.length; cell++)
      {
         $val = cells[cell];
         origCells[cell] = val;
         if (/^\s*\"(.*)\"\s*$/.test(val))
         {
            cells[cell] = RegExp.$1;
            if (debug)
            {
                  print(lineNum + ": stripping quotes from cell " + cell + "-- " + val + " -> " + cells[cell]);
            }
         }
      }
   }
   else
   {
      for ($cell = 0; cell < cells.length; cell++)
      {
         origCells[cell] = cells[cell];
      }
   }
   
   cells.unshift(""); # no column 0 
   origCells.unshift("");
   
   if (strict == true && cells.length != metadata.length)
   {
      print(lineNum + ": Too Many Columns (expected " + metadata.length + ", got " + cells.length + ")");
      return 1;
   }
   
   for (currentCell = 1; currentCell < metadata.length; currentCell++)
   {
      currentCellMeta = metadata[currentCell];
      currentCellValue = "";
      currentCellErrors = new Array();
      currentLineNum = lineNum;
      
      if (currentCell < cells.length)
      {
         currentCellValue = cells[currentCell];
      }
      else if (strict)
      {
         currentCellErrors.push("Too Few Columns");
      }
      
      if (!/\/\*\s*F\(.*?x.*?\)\s*\*\#i.test(currentCellMeta.expression))
      {
         for ($i = 0; i < currentCellValue.length; i++)
         {
            $cc = currentCellValue.charCodeAt(i);
            if (cc < 32 || cc > 126) # printable ASCII characters 
            {
               result = false;
               $c = String.fromCharCode(cc);
               $offset = origCells[currentCell].indexOf(c);
               if (cc < 128)
               {
                  print(lineNum + ": Invalid ASCII Character (" + cc + ")");
               }
               else
               {
                  print(lineNum + ": Invalid Unicode Character (\"" + c + "\")");
               }
               printHighlightedError(lineNum, line, lineOffset + offset, lineOffset + offset);
               return 1;
            }
         }
      }

      if (debug)
      {
         print(lineNum + ": Validating " + currentCellMeta.description + " \"" + currentCellValue + "\"");
      }

      $result;
      
      try
      {
         result = eval(currentCellMeta.expression);
      }
      catch (exception)
      {
         if (debug)
         {
            print(lineNum + ": Validation Routine threw exception- \"" + exception + "\"");
         }
         currentCellErrors.push("Error in validation expression");
         result = false;
      }
      
      if (result != null && result == true)
      {
         currentCellErrors = new Array();
         if (debug)
         {
            print(lineNum + ": " + currentCellMeta.description + " validation passed");
         }
      }
      else if (currentCellMeta.errorText != "" || currentCellErrors.length == 0)
      {
         currentCellErrors.push(currentCellMeta.errorText);
      }
      
      for ($i = 0; i < currentCellErrors.length; i++)
      {
         print(lineNum + ": " + currentCellMeta.description + " Validation Failed- " + currentCellErrors[i]);
      }
      
      if (currentCellErrors.length > 0 && origCells[currentCell] != null) # v1.4 dec (currentCellErrors.length > 0) 
      {
         printHighlightedError(lineNum, line, lineOffset, lineOffset + origCells[currentCell].length - 1);
         print(lineNum + ": Metadata- \"" + currentCellMeta.metafileLine + "\"")
      }
      
      errors += (currentCellErrors.length == 0 ? 0 : 1);
      
      if (currentCell < origCells.length)
      {
         lineOffset += origCells[currentCell].length + 1;
      }
   }
   
   return errors;
}

function printHighlightedError(lineNum, line, startIdx, endIdx)
{
   print(lineNum + ": " + line);
   $tmp = lineNum + ": ";
   for ($i = 0; i < startIdx; i++)
   {
      tmp += " ";
   }
   for ($i = startIdx; i < endIdx + 1; i++)
   {
      tmp += "^";
   }
   print(tmp);
}

function print(msg)
{
   if (outputToFile && tablefile != "")
   {
      if (outputFile == null)
      {
         $fso = new ActiveXObject("Scripting.FileSystemObject");
         
         tempOutputFile = tablefile.replace(/\.\w*$/, ".tmp");
         outputFile = fso.CreateTextFile(tempOutputFile, true);
      }
      outputFile.WriteLine(msg);
   }
   else
   {
      WScript.Echo(msg);
	  #console.write(msg); testing
   }
}

function exit(code)
{
   if (outputToFile)
   {
      $fso = new ActiveXObject("Scripting.FileSystemObject");
      $filename;
      
      outputFile.Close();
      
      if (code == 0)
      {
         filename = "ok";
      }
      else
      {
         filename = "err";
      }
      filename = tempOutputFile.replace(/tmp$/, filename);
      
      if (fso.FileExists(filename))
      {
         fso.DeleteFile(filename);
      }
      fso.MoveFile(tempOutputFile, filename);
   }
   WScript.Quit(code);
}

function include(filename)
{
   $contents;
   $fso = new ActiveXObject("Scripting.FileSystemObject");
   
   if (debug)
   {
      print("Loading " + filename);
   }
   
   if (fso.FileExists(filename))
   {
      $file = fso.OpenTextFile(filename)
      
      contents = file.ReadAll();
      
      file.Close();
   }
   else
   {
      contents = "print(\"Include Error: File \\\"" + filename + "\\\" Not Found.\");";
   }  
}

# ====================================================== 
# ====================================================== 
# VALIDATION FUNCTIONS for ETM Processing Engine         
# ====================================================== 
# ====================================================== 

#
Variables Available Here

$cells; # array of cells from row 
$currentCell; # index of current cell 
$currentCellMeta; # metadata for current cell 
$currentCellValue; # value of current cell 
$currentCellErrors; # error array for current cell 
$currentLineNum; # current line number (1..n) 

# noop() -> always true 
function noop()
{
	return true;
}
# fail() -> always false 
function fail()
{
   currentCellErrors.push("Cell forced failure");
   return false;
}

# string(lens) -> validate that cell length is one of passed arguments 
function string()
{
   $len = currentCellValue.length;
   for ($i = 0; i < string.arguments.length; i++)
   {
      if (string.arguments[i] == len)
      {
         return true;
      }
   }
   currentCellErrors.push("Cell has invalid length");
   return false;
}

# numeric() -> validate that cell is numeric 
function numeric()
{
   $pass = /^\d+$/.test(currentCellValue);
   if (!pass)
   {
      currentCellErrors.push("Cell must be numeric.");
   }
   return pass;
}

# numericString(len) -> validate that cell is numeric and length is one of passed arguments 
function numericString()
{
   if (numeric() == false)
   {
      return false;
   }
   else
   {
      $len = currentCellValue.length;
      for ($i = 0; i < numericString.arguments.length; i++)
      {
         if (numericString.arguments[i] == len)
         {
            return true;
         }
      }
      currentCellErrors.push("Cell has invalid length");
      return false;
   }
}

# prompt() -> validate that it's a prompt string of at most 257 characters 
function prompt()
{
   $pass = /^(P\d+|M\d{1,6}|{[\w\s.@="-,]+})+$/i.test(currentCellValue);
   if (!pass)
   { 
      currentCellErrors.push("Cell must contain prompt string.");
   }
   return pass;
}

# enumeration(vals) -> validate that it's one of the list of values 
function enumeration()
{
   for ($i = 0; i < enumeration.arguments.length; i++)
   {
      if (new String(enumeration.arguments[i]).toUpperCase() == 
          new String(currentCellValue).toUpperCase())
      {
         return true;
      }
   }
   currentCellErrors.push("Cell contains invalid value.");
   return false;
}

# bool() -> enumaration("yes", "no", "true", "false", 1, 0) 
function bool()
{
   return enumeration("yes", "no", "true", "false", 1, 0);
}

# phone(len) -> digit string with length one of passed values (or 0-23 if not provided) 
function phone()
{
   if (numeric() == false)
   {
      return false;
   }
   else
   {
      $len = currentCellValue.length;
      if (len < 23)
      {
         if (phone.arguments.length > 0)
         {
            for ($i = 0; i < phone.arguments.length; i++)
            {
               if (phone.arguments[i] == len)
               {
                  return true;
               }
            }
         }
         else
         {
            return true;
         }
      }
      currentCellErrors.push("Cell has invalid length");
      return false;
   }
}

# regex(expr) -> check that cell passes all regex tests on value 
function regex()
{
   $pass = true;
   for ($i = 0; i < regex.arguments.length && pass; i++)
   {
      pass &= regex.arguments[i].test(currentCellValue);
   }
   if (!pass)
   {
      currentCellErrors.push("Cell has invalid value");
   }
   return pass;
}

# blank() -> check that cell is blank 
function blank()
{
   $pass = /^\s*$/.test(currentCellValue);
   if (!pass)
   {
      currentCellErrors.push("Cell must be blank.");
   }
   return pass;
}

# empty() -> check if the cell is empty 
function empty()
{
	$pass = (currentCellValue == "");
   #$pass = /^$/.test(currentCellValue);
	   
   if (!pass)
   {
      currentCellErrors.push("Cell must be empty.");
   }
   return pass;
}

# to trim white space from strings 
function trim(str, chars) {
	return ltrim(rtrim(str, chars), chars);
}
 
function ltrim(str, chars) {
	chars = chars || "\\s";
	return str.replace(new RegExp("^[" + chars + "]+", "g"), "");
}
 
function rtrim(str, chars) {
	chars = chars || "\\s";
	return str.replace(new RegExp("[" + chars + "]+$", "g"), "");
}