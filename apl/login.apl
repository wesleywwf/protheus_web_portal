#include "protheus.ch"
#include "apwebex.ch"
#include "tbiconn.ch"

// Monta form de login
// Se lErro for verdadeiro, mensagem de erro será exibida
user function portal1(lErro)
  local cHtml := ''
  private lExibirMensagem := .f.

  if lErro
    lExibirMensagem := .t.
  endif
  cHtml := h_form_login()
return cHtml       

// Autentica form de login
user function portal2()

  local cHtml := ''
  local _cUsuario := HttpPost->usuario
  local _cSenha := HttpPost->senha

  PswOrder(2)
  if PswSeek(_cUsuario, .t.) .and. PswName(_cSenha) .and. !empty(_cUsuario + _cSenha)


    HttpSession->logado := .t.
    HttpSession->UserId := PswID()
    // Xunxo para garantir que uma área está aberta antes de chamar UsrFullName(), senão dá erro...
    Select('SC1')
    HttpSession->NomeUsuario := UsrFullName(httpsession->UserId)
    cHtml := redirpage('/u_index.apw?modulo=compras')
  else
    HttpSession->logado := .f.
    cHtml := u_portal1(.t.)
  endif

return cHtml

// Desloga e redireciona usuário para tela de login
user function portal5()

  local cHtml := ''

  HttpSession->logado := .f.
  HttpSession->UserId := nil
  HttpSession->NomeUsuario := nil
  HttpFreeSession()
  cHtml := redirpage('/u_index.apw?modulo=login')

return cHtml