# BitRun Workstation Manager 🚀

Um ecossistema de automação desenvolvido em **Python (CircuitPython)** e **PowerShell**, projetado para otimização de fluxos de trabalho em estações de trabalho Windows usando o microcontrolador **RP2040**.

## 🛠️ Funcionalidades Técnicas

- **Deployment Dinâmico:** Gerenciamento de scripts remotos via GitHub API para instalação de softwares (IDEs, ferramentas de produtividade).
- **Network Diagnostics:** Scripts para auditoria de latência e coleta de metadados de conectividade (IP-API).
- **System Hardening & Cleanup:** Rotinas de limpeza de arquivos temporários e otimização de memória RAM.
- **Hardware Telemetry:** Extração automatizada de especificações técnicas via WMI (Windows Management Instrumentation).
- **HID Emulation:** Interface de hardware personalizada para execução de macros de produtividade.

## 📁 Estrutura do Repositório

- `/escola`: Ferramentas de produtividade acadêmica e foco.
- `/pessoal`: Automação de deploy de softwares e ambiente de desenvolvimento.
- `/coleta`: Diagnósticos de sistema e telemetria de rede.
- `mestre.ps1`: Orquestrador principal de scripts em PowerShell.

## 🚀 Tecnologias Utilizadas
- **Linguagens:** Python (CircuitPython), PowerShell.
- **Hardware:** Raspberry Pi Pico (RP2040), Display TFT ST7735.
- **Protocolos:** SPI, I2C, HID, REST API.
