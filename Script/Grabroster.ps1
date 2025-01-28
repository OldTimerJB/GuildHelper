function Convert-LuaToPSCustomObject {
    param (
        [string]$luaFilePath
    )

    # Read the Lua file content
    $luaContent = Get-Content -Path $luaFilePath -Raw

    # Remove Lua comments (single-line comments starting with --)
    $luaContent = $luaContent -replace "--.*", ""  # Remove single-line comments
    $luaContent = $luaContent.Trim()  # Remove leading/trailing whitespaces

    # Initialize the root object
    $rootObject = @{}

    # Parse the Lua content to key-value pairs (recursive)
    $rootObject = Parse-LuaContent $luaContent

    # Convert the hashtable to a PSCustomObject
    $psCustomObject = New-Object PSCustomObject

    # Add each key-value pair to the PSCustomObject
    foreach ($key in $rootObject.Keys) {
        $psCustomObject | Add-Member -MemberType NoteProperty -Name $key -Value $rootObject[$key]
    }

    return $psCustomObject
}

# Function to parse the Lua content recursively
function Parse-LuaContent {
    param (
        [string]$luaContent
    )

    $parsedData = @{}
    $lines = $luaContent.Split("`n")  # Split content by newlines

    foreach ($line in $lines) {
        $line = $line.Trim()

        # Ignore empty lines
        if (-not $line) {
            continue
        }

        # Match key-value pairs with potential arrays or nested tables
        if ($line -match '^\["?(.*?)"?\]\s*=\s*(.*)$') {
            $key = $matches[1]
            $value = $matches[2].Trim()

            # If the value looks like a table (starts with '{' and ends with '}')
            if ($value.StartsWith("{") -and $value.EndsWith("}")) {
                $parsedData[$key] = Parse-LuaContent $value.Trim('{}')  # Recursive call for nested tables
            }
            # If the value looks like an array (starts with '[' and ends with ']')
            elseif ($value.StartsWith("[") -and $value.EndsWith("]")) {
                $parsedData[$key] = Parse-LuaArray $value.Trim('[]')  # Call array parsing function
            }
            else {
                # Remove quotes around string values
                if ($value.StartsWith('"') -and $value.EndsWith('"')) {
                    $value = $value.Substring(1, $value.Length - 2)  # Remove quotes
                }
                elseif ($value.StartsWith("'") -and $value.EndsWith("'")) {
                    $value = $value.Substring(1, $value.Length - 2)  # Remove quotes
                }

                # Add the key-value pair to the parsed data
                $parsedData[$key] = $value
            }
        }
    }

    return $parsedData
}

# Function to parse Lua arrays (simple arrays)
function Parse-LuaArray {
    param (
        [string]$luaArrayContent
    )

    $arrayData = @()
    $elements = $luaArrayContent.Split(",")  # Split the array by commas

    foreach ($element in $elements) {
        $element = $element.Trim()

        # If the element is a quoted string, remove quotes
        if ($element.StartsWith('"') -and $element.EndsWith('"')) {
            $element = $element.Substring(1, $element.Length - 2)
        }

        # Add the element to the array
        $arrayData += $element
    }

    return $arrayData
}

# Example usage:
$luaFilePath = "C:\path\to\your\SavedVariables.lua"
$psObject = Convert-LuaToPSCustomObject -luaFilePath $luaFilePath

# Display the result
($psObject).count


$luaFilePath = C:\Program Files (x86)\World of Warcraft\_retail_\WTF\Account\JBMAN8\SavedVariables\GuildHelper.lua'
