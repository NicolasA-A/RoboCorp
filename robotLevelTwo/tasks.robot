*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${True}
Library             RPA.Excel.Files
Library             RPA.HTTP
Library             RPA.Tables
Library             DateTime
Library             RPA.Windows
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs
Library             OperatingSystem


*** Tasks ***
Main
    # https://robotsparebinindustries.com/orders.csv
    ${url}=    Input form dialog
    Download order website    ${url}
    Open web site form
    ${table}=    Read CSV file
    FOR    ${column}    IN    @{table}
        ${element}    ${number}=    Fill form    ${column}
        Convert html to pdf    ${element}    ${number}
        ${list}=    Create List    ${OUTPUT_DIR}${/}orders${/}${number}.png
        Add Files To Pdf    ${list}    ${OUTPUT_DIR}${/}orders${/}${number}.pdf    ${True}
    END
    Archive Folder With Zip    ${OUTPUT_DIR}${/}orders${/}    orders.zip
    Delete files


*** Keywords ***
Download order website
    [Arguments]    ${url}
    Download    ${url}    overwrite=true

Read CSV file
    ${table}=    Read table from CSV    orders.csv    true    delimiters=,
    RETURN    ${table}

Fill form
    [Arguments]    ${column}
    Select From List By Value    css:select.custom-select    ${column}[Head]
    Click Element    id:id-body-${column}[Body]
    Input Text    css:input.form-control    ${column}[Legs]
    Input Text    id:address    ${column}[Address]
    Click Button    id:order
    Set Wait Time    0.5
    ${res}=    Does Page Contain Element    class:alert-danger
    ${inc}=    Set Variable    ${0}
    WHILE    ${inc} < 5
        IF    ${res} == ${True}    Click Button    id:order    ELSE    BREAK
        ${res}=    Does Page Contain Element    class:alert-danger
        ${inc}=    Set Variable    ${inc+1}
    END
    Wait Until Page Contains Element    id:order-completion
    ${element}=    Get Element Attribute    id:receipt    outerHTML
    ${number}=    Get Element Attribute    css:p.badge-success    textContent
    Take a screenshot    id:order-completion    ${number}
    Click Button    id:order-another
    Wait Until Page Contains Element    css:div.modal-content
    Click Button    OK
    RETURN    ${element}    ${number}

Open web site form
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Wait Until Page Contains Element    css:div.modal-content
    Click Button    OK

Convert html to pdf
    [Arguments]    ${element}    ${num}
    Html To Pdf    ${element}    ${OUTPUT_DIR}${/}orders${/}${num}.pdf

Take a screenshot
    [Arguments]    ${element}    ${num}
    RPA.Browser.Selenium.Screenshot    ${element}    ${OUTPUT_DIR}${/}orders${/}${num}.png

Input form dialog
    Add heading    Input URL csv orders
    Add text input    url    label=Url
    ${result}=    Run dialog
    RETURN    ${result.url}

Delete files
    ${files}=    List Files In Directory    ${OUTPUT_DIR}${/}orders${/}
    FOR    ${file}    IN    @{files}
        Remove File    ${OUTPUT_DIR}${/}orders${/}${file}
    END
