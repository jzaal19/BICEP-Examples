$GitBasePath = "D:\DataCompany\jzaal\OneDrive - Huisman Equipment B.V\BICEPGitRepo\BICEP-Examples"

Login-AzAccount

Set-AzContext -Subscription "huisman-general-d-001"

bicep build "$GitBasePath\main.bicep"

New-AzResourceGroupDeployment -TemplateFile "$GitBasePath\main.bicep" -ResourceGroupName "rg-weu-jzaal-t-001"

New-AzResourceGroupDeployment -TemplateFile "$GitBasePath\main.bicep" -ResourceGroupName "rg-weu-jzaal-t-001" -storageSKU "Standard_GRS"