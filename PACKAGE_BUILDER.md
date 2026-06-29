# Gerador de pacotes SCCM / Intune

O gerador cria uma nova estrutura de aplicação a partir de uma cópia de
`DWP - Application Template`. O template original nunca é editado.

## Uso

1. Execute `Start-PackageBuilder.cmd`.
2. Selecione o arquivo MSI.
3. Revise os metadados extraídos. O executável e a versão de detecção são
   opcionais, pois o `ProductCode` do MSI também pode ser usado para detecção.
4. Escolha se versões anteriores devem ser removidas pelo nome ou somente pelo
   `ProductCode` selecionado.
5. Clique em **Gerar pacote**.

A saída segue o padrão:

`Fabricante_Aplicativo_Versão_Sistema_Idioma`

Cada pacote recebe `Install.ps1`, `Uninstall.ps1`, `Modules`, `Prog` com o MSI e
`PackageInfo.json` com os dados usados na geração.

## Requisitos

- Windows PowerShell 5.1
- Windows Installer disponível no Windows
- Execução em uma sessão gráfica do Windows
