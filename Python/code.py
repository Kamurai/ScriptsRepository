urls = (
	"/favicon.ico", "icon",
	"/", "index",
	"/index", "index",
	"/AboutUs", "AboutUs",
	"/Media", "Media",
	"/Minecraft", "Minecraft",
	
	"/Section1/index", "Section1",
	"/Section2/index", "Section2",
	"/Section3/index", "Section3",
	"/Section3/Project1", "Section3_1",
	"/Section3/Project2", "Section3_2",
	"/Section3/Project3", "Section3_3"
)

Main = web.template.render('/')
Universal = web.template.render('/Universal')
MainContent = web.template.render('Content/')
Section1 = web.template.render('Section1/')
Section2 = web.template.render('Section2/')
Section3 = web.template.render('Section3/')

class icon:
    def GET(self):
        return Main.Universal()

class index:
    def GET(self):
        return Main.Layout(0, 0, "Main.css")

class AboutUs:
    def GET(self):
        return Main.Layout(1, 0, "Main.css")

class Media:
    def GET(self):
        return Main.Layout(2, 0, "Main.css")

class Minecraft:
    def GET(self):
        return Main.Layout(3, 0, "Main.css")

class Section1:
    def GET(self):
        return Section1.Layout(0, 1, "Section1.css")

class Section2:
    def GET(self):
        return Section2.Layout(0, 1, "Section2.css")

class Section3:
    def GET(self):
        return Section3.Layout(0, 1, "Section3.css")

class Section3_1
    def GET(self):
        return Section3.Layout(1, 1, "Section3.css")

class Section3_2:
    def GET(self):
        return Section3.Layout(2, 1, "Section3.css")

class Section3_3:
    def GET(self):
        return Section3.Layout(3, 1, "Section3.css")

		
		
		
		
		
		
		