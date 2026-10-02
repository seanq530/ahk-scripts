^+e::
Url := "https://the-internet.herokuapp.com/login"
UserName := "tomsmith"
Password := "SuperSecretPassword!"
web_browser := ComObjCreate("InternetExplorer.Application")
web_browser.Visible := True
web_browser.navigate(Url)
while web_browser.busy
{
sleep 500 
}
sleep 1000
usernamme_input := web_browser.document.getElementbyID("username")
usernamme_input.value := UserName
password_input := web_browser.document.getElementbyID("password")
password_input.value := Password
web_browser.document.getElementbyID("login").submit()
return