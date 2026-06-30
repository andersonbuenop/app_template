# Gerador de pacotes SCCM / Intune

O gerador cria uma nova estrutura de aplicação MSI ou EXE a partir de uma cópia de
`DWP - Application Template`. O template original nunca é editado.

## Uso

1. Execute `Start-PackageBuilder.cmd`.
2. Selecione o instalador MSI ou EXE.
3. Revise os metadados extraídos. O executável e a versão de detecção são
   opcionais para MSI, pois o `ProductCode` também pode ser usado para detecção.
   Para EXE, informe o executável e a versão usados na detecção.
4. Escolha se versões anteriores devem ser removidas pelo nome ou somente pelo
   `ProductCode` selecionado.
5. Clique em **Gerar pacote**.

## Instaladores EXE

EXE não possui um padrão único de instalação silenciosa. Revise sempre:

- argumentos silenciosos de instalação;
- caminho do desinstalador depois da instalação;
- argumentos silenciosos de desinstalação;
- executável e versão usados na detecção.

Para o instalador oficial do 7-Zip, a interface sugere os parâmetros conhecidos,
mas eles continuam editáveis antes da geração.

A saída segue o padrão:

`Fabricante_Aplicativo_Versão_Sistema_Idioma`

Cada pacote recebe `Install.ps1`, `Uninstall.ps1`, `Modules`, `Prog` com o MSI e
`PackageInfo.json` com os dados usados na geração.

## Requisitos

- Windows PowerShell 5.1
- Windows Installer disponível no Windows
- Execução em uma sessão gráfica do Windows
