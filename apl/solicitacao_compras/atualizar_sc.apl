#include "protheus.ch"
#include "apwebex.ch"
#include "tbiconn.ch"
#include 'topconn.ch'

// Monta tela de detalhe de sc
user function portal8()

  local cHtml := ''

  Local aCabec := {}
  Local aItens := {}
  Local aLinha := {}
  Local nOp    := 4 // Opções do MATA110: 3 = edição, 4 = alteração, 5 = exclusão
  Private aErros := {}
  Private lMsHelpAuto := .T.
  Private lMsErroAuto := .F.
  Private lAutoErrNoFile := .T. // para capturar erros de execauto via array

  // Se código veio da página de edição, usa, senão, usa o código obtido da SX na criação
  if HttpPost->codigo == nil 
    nC1_NUM := GetSXENum("SC1","nC1_NUM") 
  else
    nC1_NUM := HttpPost->codigo
  endif
  conout(">>>>>>>>>>>>>> nC1_NUM: " + nC1_NUM)

  aadd(aCabec,{"C1_NUM", nC1_NUM})
  aadd(aCabec,{"C1_SOLICIT","Administrador"}) //TODO: pegar o usuário logado na inclusão? não alterar?
  aadd(aCabec,{"C1_EMISSAO", CTOD(HttpPost->C1_EMISSAO)})
  aadd(aCabec,{"C1_CODCOMP", HttpPost->C1_CODCOMP})

  // Extrai itens enviados via http para array de itens
  aCamposItem := {'C1_ITEM', 'C1_PRODUTO', 'C1_QUANT', 'C1_D_E_L_E_T_'} // lista de campos de itens que serão recebidos com final "_x" sendo x a numeração
  For i := 1 to val(HttpPost->total_itens) // campo de controle de qtd de itens recebidos
    aItens := {} // limpa itens, pois devido à possibilidade de exclusão de item, é um exectauto por item
    aLinha := {}
    nOp    := 4 // volta modo do execauto para alteração por padrão
    For j := 1 to len(aCamposItem)
      cCampo := aCamposItem[j]
      cValor := ''
      // Atribui o valor do campo via macro substituição. O código executado será algo como: 
      // cValor := HttpPost->C1_ITEM_1
      cMacroSub := 'cValor := HttpPost->' + cCampo + '_' + cvaltochar(i)
      &(cMacroSub)
      // Trata exceções, como campos numéricos
      cValor := alltrim(cValor)
      if cCampo == "C1_QUANT"
        cValor := val(alltrim(cValor))
      elseif cCampo == 'C1_ITEM' .and. cValor == '*'
        // Teste se adicionando C1_ITEM a exclusão ocorre só com o item
        aadd(aCabec,{"C1_ITEM", cValor})
      elseif cCampo == 'C1_D_E_L_E_T_' .and. cValor == '*'
        //nOp := 5 // muda modo do execauto para exclusao // COMENTADO PORQUE EXCLUI TODOS OS ITENS
      endif
      // Adiciona campo ao item a ser atualizado
      if cCampo != 'C1_D_E_L_E_T_' .and. cvaltochar(cValor) != '' // só usa o campo delete se o item foi marcado para exclusao
        aadd(aLinha,{cCampo, cValor,  Nil})
      endif
    Next j
    // Adiciona linha de item a ser atualizado
    aadd(aItens,aLinha) 

    // Testa se é inclusão e caso o código da sc não tenha sido enviado, e muda a a operação para inclusao
    if HttpPost->codigo == nil
      nOp := 3
    endif

    // Executa a alteração ou exclusão. Pára se ocorrer erro
    MSExecAuto({|x,y| mata110(x, y, nOp)}, aCabec, aItens)
    If !lMsErroAuto
      HttpSession->alert := 'success'
      // Se for inclusao, confirma novo código na sx8
      if HttpPost->codigo == nil
        HttpSession->alert := 'inclusao'
        ConfirmSX8()
      endif
    Else
      HttpSession->alert := 'error'
      aErros := GetAutoGRLog()
      exit
    EndIf
  Next i

  _cQuery := "select SC1.*, SB1.B1_DESC from " + RetSqlName("SC1") + " SC1 "
  _cQuery += "left join " + RetSqlName("SB1") + " SB1 on "
  _cQuery += "C1_PRODUTO = B1_COD "
  _cQuery += "where SC1.D_E_L_E_T_ <> '*' AND SB1.D_E_L_E_T_ <> '*' AND C1_FILIAL = B1_FILIAL "
  _cQuery += "and SC1.C1_NUM ='" + nC1_NUM + "' "

  If Select('SC1') <> 0
    SC1->(DbCloseArea())
  Endif

  TcQuery _cQuery New Alias "SC1"
  dbselectarea("SC1")
  SC1->(dbgotop())

  cHtml := h_edit_sc()
  //cHtml := redirpage('/u_index.apw?modulo=compras&acao=edicao_sc&codigo='+ HttpGet->codigo)

  dbCloseArea("SC1") 
    
return cHtml