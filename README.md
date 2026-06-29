# SCCM / Intune App Package Builder

Gerador com interface gráfica para criar pacotes PowerShell de aplicações MSI
a partir do template DWP. A ferramenta copia o template, preenche os dados da
aplicação e adiciona o instalador à pasta `Prog` sem modificar o template
original.

## Estrutura

- `AppPackageBuilder.ps1`: interface e lógica de geração.
- `Start-PackageBuilder.cmd`: inicializador para Windows PowerShell 5.1.
- `DWP - Application Template`: template original usado como fonte.
- `Examples/Bruno`: exemplo de pacote baseado no template.
- `Examples/7Zip`: exemplo completo com MSI.
- `PACKAGE_BUILDER.md`: instruções detalhadas.

## Uso rápido

1. Clone ou baixe o repositório em um computador Windows.
2. Execute `Start-PackageBuilder.cmd`.
3. Selecione o MSI e revise os metadados extraídos.
4. Preencha os campos opcionais necessários, como processos a fechar.
5. Confirme o diretório de saída e clique em **Gerar pacote**.

O nome gerado segue o padrão:

```text
Fabricante_Aplicativo_Versão_Sistema_Idioma
```

O resultado contém `Install.ps1`, `Uninstall.ps1`, `Modules`, `Prog` e
`PackageInfo.json`. A importação no SCCM ou Intune continua sendo manual.

## Requisitos

- Windows PowerShell 5.1
- Windows Installer
- Sessão gráfica do Windows para a interface WPF

## Segurança

O gerador nunca sobrescreve uma pasta de pacote existente. Revise e teste os
scripts gerados em um ambiente controlado antes da distribuição.
