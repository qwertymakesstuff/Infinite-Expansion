# Lints PowerShell scripts that must run in Windows PowerShell 5.1 while being
# tested with PowerShell 7: parse errors, PowerShell 7 syntax, and commands or
# parameters 5.1 does not have. Prints one line per problem; no output = clean.
#
#   pwsh -NoProfile -File tools/tests/ps51_lint.ps1 <file.ps1> [...]
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Files)

$ps7Commands = @('join-string', 'test-json', 'get-error')
$ps7Parameters = @{
    'convertfrom-json' = @('ashashtable', 'depth', 'noenumerate')
    'split-path'       = @('leafbase', 'extension')
    'get-content'      = @('asbytestream')
    'set-content'      = @('asbytestream')
    'foreach-object'   = @('parallel', 'throttlelimit')
    'join-path'        = @('additionalchildpath')
}
$ps7Variables = @('iswindows', 'islinux', 'ismacos', 'iscoreclr')

foreach ($file in $Files) {
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$tokens, [ref]$errors)
    foreach ($e in $errors) {
        Write-Output ("{0}:{1}: parse error: {2}" -f $file, $e.Extent.StartLineNumber, $e.Message)
    }

    $syntax = $ast.FindAll({
            param($n)
            ($n -is [System.Management.Automation.Language.TernaryExpressionAst]) -or
            ($n -is [System.Management.Automation.Language.PipelineChainAst]) -or
            ($n -is [System.Management.Automation.Language.BinaryExpressionAst] -and $n.Operator -eq 'QuestionQuestion') -or
            ($n -is [System.Management.Automation.Language.AssignmentStatementAst] -and $n.Operator -eq 'QuestionQuestionEquals') -or
            ($n -is [System.Management.Automation.Language.MemberExpressionAst] -and $n.NullConditional)
        }, $true)
    foreach ($n in $syntax) {
        Write-Output ("{0}:{1}: PowerShell 7 syntax: {2}" -f $file, $n.Extent.StartLineNumber, $n.Extent.Text)
    }

    $commands = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true)
    foreach ($command in $commands) {
        $name = $command.GetCommandName()
        if (-not $name) {
            continue
        }
        $name = $name.ToLowerInvariant()
        $parameters = @($command.CommandElements |
                Where-Object { $_ -is [System.Management.Automation.Language.CommandParameterAst] } |
                ForEach-Object { $_.ParameterName.ToLowerInvariant() })
        $line = $command.Extent.StartLineNumber
        if ($ps7Commands -contains $name) {
            Write-Output ("{0}:{1}: not in Windows PowerShell 5.1: {2}" -f $file, $line, $name)
        }
        if ($ps7Parameters.ContainsKey($name)) {
            foreach ($parameter in $parameters) {
                if ($ps7Parameters[$name] -contains $parameter) {
                    Write-Output ("{0}:{1}: not in Windows PowerShell 5.1: {2} -{3}" -f $file, $line, $name, $parameter)
                }
            }
        }
        if ($name -eq 'join-path') {
            $positional = @($command.CommandElements | Select-Object -Skip 1 |
                    Where-Object { $_ -isnot [System.Management.Automation.Language.CommandParameterAst] }).Count
            if ($positional -gt 2) {
                Write-Output ("{0}:{1}: Join-Path takes only two parts in Windows PowerShell 5.1" -f $file, $line)
            }
        }
    }

    $variables = $ast.FindAll({
            param($n)
            $n -is [System.Management.Automation.Language.VariableExpressionAst] -and
            $ps7Variables -contains $n.VariablePath.UserPath.ToLowerInvariant()
        }, $true)
    foreach ($n in $variables) {
        Write-Output ("{0}:{1}: undefined in Windows PowerShell 5.1: {2}" -f $file, $n.Extent.StartLineNumber, $n.Extent.Text)
    }
}
