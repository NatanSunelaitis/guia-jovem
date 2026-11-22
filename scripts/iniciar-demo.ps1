# Sobe a demonstração local: API contra o banco guiajovem_demo, a caixa de
# e-mails de testes (MailDev: SMTP local e interface web, sem Docker e sem
# internet), build web release do app e um servidor estático para ele, todos
# em segundo plano. Para parar: parar-demo.cmd.
#
#   iniciar-demo.cmd [-PortaApi 3000] [-PortaApp 8080] [-PortaSmtp 1025] [-PortaEmail 1080] [-SemBuild]
#
# -SemBuild reaproveita o app/build/web existente (precisa ter sido gerado
# para a mesma porta da API).
param(
  [int]$PortaApi = 3000,
  [int]$PortaApp = 8080,
  [int]$PortaSmtp = 1025,
  [int]$PortaEmail = 1080,
  [switch]$SemBuild
)

$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot
$pastaApi = Join-Path $raiz 'api'
$pastaApp = Join-Path $raiz 'app'
$pastaBuild = Join-Path $pastaApp 'build\web'
$estado = Join-Path $raiz '.demo'
$arquivoPids = Join-Path $estado 'pids.json'
$urlApi = "http://localhost:$PortaApi"
$urlApp = "http://localhost:$PortaApp"
$urlEmail = "http://localhost:$PortaEmail"

function Falhar([string]$mensagem) {
  Write-Host ''
  Write-Host "ERRO: $mensagem" -ForegroundColor Red
  exit 1
}

function Etapa([string]$mensagem) {
  Write-Host "> $mensagem" -ForegroundColor Cyan
}

function Esperar([string]$url, [int]$segundos, $processo) {
  $limite = (Get-Date).AddSeconds($segundos)
  while ((Get-Date) -lt $limite) {
    if ($processo -and $processo.HasExited) { return $false }
    try {
      $resposta = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3
      if ($resposta.StatusCode -eq 200) { return $true }
    } catch {
      Start-Sleep -Milliseconds 500
    }
  }
  return $false
}

# Sobe um processo node em segundo plano, com a saída e os erros em arquivos,
# e devolve o processo node. Antes era Start-Process com -RedirectStandard*,
# que cria o processo herdando os handles deste PowerShell: quando quem chamou
# o iniciar-demo.cmd lia a saída por um pipe (iniciar-demo.cmd | more, o
# terminal de uma IDE, um script), a API e o servidor do app ficavam com o
# pipe aberto e o comando não devolvia o terminal enquanto eles rodassem.
# Sem redirecionamento, o Start-Process usa o ShellExecute, que não passa
# handles adiante; quem grava os logs é o cmd oculto que inicia o node.
function IniciarNode([string]$argumentos, [string]$saida, [string]$erro) {
  $linha = "/d /s /c `"node $argumentos > `"$saida`" 2> `"$erro`"`""
  $cmd = Start-Process cmd.exe -ArgumentList $linha -WorkingDirectory $pastaApi -WindowStyle Hidden -PassThru
  $limite = (Get-Date).AddSeconds(15)
  while ((Get-Date) -lt $limite) {
    $filho = Get-CimInstance Win32_Process -Filter "ParentProcessId=$($cmd.Id) AND Name='node.exe'" | Select-Object -First 1
    if ($filho) { return Get-Process -Id $filho.ProcessId }
    if ($cmd.HasExited) { break }
    Start-Sleep -Milliseconds 200
  }
  return $null
}

function Parar($processos) {
  foreach ($p in $processos) {
    if ($p -and -not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
  }
}

# 1. Pré-condições
if (Test-Path $arquivoPids) {
  $anteriores = Get-Content $arquivoPids -Raw | ConvertFrom-Json
  $vivos = @($anteriores.api, $anteriores.app, $anteriores.email) | Where-Object { $_ -and (Get-Process -Id $_ -ErrorAction SilentlyContinue) }
  if ($vivos) { Falhar 'A demonstração já está rodando. Rode parar-demo.cmd antes de iniciar de novo.' }
  Remove-Item $arquivoPids
}
if (-not (Get-Command node -ErrorAction SilentlyContinue)) { Falhar 'Node.js não encontrado no PATH.' }
if (-not $SemBuild -and -not (Get-Command flutter -ErrorAction SilentlyContinue)) { Falhar 'Flutter não encontrado no PATH (ou use -SemBuild com um build já gerado).' }
if (-not (Test-Path (Join-Path $pastaApi 'node_modules'))) { Falhar 'Dependências da API ausentes. Rode na pasta api: npm install' }

if (-not (Test-Path (Join-Path $pastaApi 'node_modules\maildev'))) { Falhar 'A caixa de e-mails de testes (MailDev) não está instalada. Rode na pasta api: npm install' }

foreach ($porta in @($PortaApi, $PortaApp, $PortaSmtp, $PortaEmail)) {
  $ocupada = Get-NetTCPConnection -LocalPort $porta -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($ocupada) {
    $dono = Get-Process -Id $ocupada.OwningProcess -ErrorAction SilentlyContinue
    Falhar "A porta $porta está ocupada por $($dono.ProcessName) (PID $($ocupada.OwningProcess)). Feche esse programa ou escolha outra porta com -PortaApi, -PortaApp, -PortaSmtp ou -PortaEmail."
  }
}

Etapa 'Conferindo o banco de demonstração'
Push-Location $pastaApi
& node scripts/demo/api-demo.js --conferir
$codigo = $LASTEXITCODE
Pop-Location
if ($codigo -ne 0) { Falhar 'O banco de demonstração não está pronto (mensagem acima).' }

# 2. Build web release
if ($SemBuild) {
  if (-not (Test-Path (Join-Path $pastaBuild 'index.html'))) { Falhar "Não há build em $pastaBuild. Rode sem -SemBuild." }
  Etapa 'Reaproveitando o build web existente'
} else {
  Etapa "Gerando o build web release (API em $urlApi/api/v1). Leva cerca de 1 minuto"
  $defines = @("--dart-define=API_BASE_URL=$urlApi/api/v1")
  $linhaGoogle = Get-Content (Join-Path $pastaApi '.env') -ErrorAction SilentlyContinue | Where-Object { $_ -match '^GOOGLE_CLIENT_ID=(.+)$' } | Select-Object -First 1
  if ($linhaGoogle) { $defines += "--dart-define=GOOGLE_CLIENT_ID=$($linhaGoogle.Split('=', 2)[1].Trim())" }
  Push-Location $pastaApp
  & flutter build web --release @defines
  $codigo = $LASTEXITCODE
  Pop-Location
  if ($codigo -ne 0) { Falhar 'O build web falhou (mensagens acima).' }
}

# 3. API e app em segundo plano
New-Item -ItemType Directory -Force $estado | Out-Null
$logs = @{
  apiSaida = Join-Path $estado 'api.log'
  apiErro = Join-Path $estado 'api-erros.log'
  appSaida = Join-Path $estado 'app.log'
  appErro = Join-Path $estado 'app-erros.log'
  emailSaida = Join-Path $estado 'email.log'
  emailErro = Join-Path $estado 'email-erros.log'
}

Etapa "Subindo a caixa de e-mails de testes em $urlEmail (SMTP na porta $PortaSmtp)"
$email = IniciarNode "node_modules/maildev/bin/maildev --smtp $PortaSmtp --web $PortaEmail --ip 127.0.0.1" $logs.emailSaida $logs.emailErro
if (-not $email) { Falhar "A caixa de e-mails não iniciou. Veja $($logs.emailErro)." }
if (-not (Esperar $urlEmail 20 $email)) {
  Parar @($email)
  Falhar "A caixa de e-mails não respondeu. Veja $($logs.emailErro)."
}

Etapa "Subindo a API em $urlApi"
$api = IniciarNode "scripts/demo/api-demo.js $PortaApi $urlApp $PortaSmtp" $logs.apiSaida $logs.apiErro
if (-not $api) { Parar @($email); Falhar "A API não iniciou. Veja $($logs.apiErro)." }
if (-not (Esperar "$urlApi/api/v1/health" 30 $api)) {
  Parar @($api, $email)
  Falhar "A API não respondeu no /health. Veja $($logs.apiErro) e $($logs.apiSaida)."
}
if (-not (Esperar "$urlApi/docs/" 10 $api)) {
  Parar @($api, $email)
  Falhar "A API subiu, mas o /docs não abriu. Veja $($logs.apiErro)."
}

Etapa "Servindo o app em $urlApp"
$app = IniciarNode "scripts/demo/servir-web.js `"$pastaBuild`" $PortaApp" $logs.appSaida $logs.appErro
if (-not $app) { Parar @($api, $email); Falhar "O servidor do app não iniciou. Veja $($logs.appErro)." }
if (-not (Esperar $urlApp 15 $app)) {
  Parar @($api, $app, $email)
  Falhar "O servidor do app não respondeu. Veja $($logs.appErro)."
}

@{ api = $api.Id; app = $app.Id; email = $email.Id; portaApi = $PortaApi; portaApp = $PortaApp; portaEmail = $PortaEmail } | ConvertTo-Json | Set-Content -Encoding utf8 $arquivoPids

Write-Host ''
Write-Host 'Demonstração no ar.' -ForegroundColor Green
Write-Host "  App:              $urlApp"
Write-Host "  API:              $urlApi/api/v1  (health em $urlApi/api/v1/health)"
Write-Host "  Documentação:     $urlApi/docs"
Write-Host "  Caixa de e-mails: $urlEmail  (todo e-mail enviado pelo sistema chega aqui)"
Write-Host "  Logs:             $estado"
Write-Host ''
Write-Host '  Contas (senha Demo@2026, ou o DEMO_SENHA usado no db:demo):'
Write-Host '    Administrador           admin@demo.guiajovem.com.br'
Write-Host '    Aluno                   beatriz@demo.guiajovem.com.br, lucas@demo.guiajovem.com.br'
Write-Host '    Universidade aprovada   univale@example.com (também uesp@, fvt@, feitu@, unitatui@, fams@example.com)'
Write-Host '    Universidade pendente   fcsboituva@example.com'
Write-Host '    Universidade reprovada  isepiedade@example.com'
Write-Host ''
Write-Host '  Para parar: parar-demo.cmd'
