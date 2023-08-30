*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive


*** Variables ***
${DOWNLOADS_FOLDER}         ${CURDIR}${/}downloads
${ORDERS_FILE}              ${DOWNLOADS_FOLDER}${/}orders.csv
${RECEIPTS_FOLDER}          ${DOWNLOADS_FOLDER}${/}receipts
${SCREENSHOTS_FOLDER}       ${DOWNLOADS_FOLDER}${/}images


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${order}
        Download and store the receipt    ${order}
        Order another Robot
    END
    Archive output PDFs
    [Teardown]    Close RobotSpareBin Browser


*** Keywords ***
Download the orders CSV file
    Download    url=https://robotsparebinindustries.com/orders.csv   target_file=${ORDERS_FILE}    overwrite=True

Get orders
    Download the orders CSV file
    ${orders}=    Read table from CSV    ${ORDERS_FILE}
    RETURN    ${orders}

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying modal
    Click Button When Visible    css:button.btn-dark

Download and store the receipt
    [Arguments]    ${order}
    ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
    ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
    Embed the robot screenshot to the receipt PDF file    ${pdf}    ${screenshot}

Fill the form
    [Arguments]    ${order}
    Select From List By Index    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    css:input.form-control[type="number"]    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    preview
    Wait Until Keyword Succeeds
    ...    5x
    ...    0.25s
    ...    Submit the form

Submit the form
    Click Button    order
    Wait Until Element Is Visible    receipt

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf}=    Set Variable    ${RECEIPTS_FOLDER}${/}${order_number}.pdf
    Html To Pdf    ${receipt_html}    ${pdf}
    RETURN    ${pdf}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${screenshot}=    Set Variable    ${SCREENSHOTS_FOLDER}${/}${order_number}.png
    Screenshot    id:robot-preview-image    ${screenshot}
    Log    "Screenshot saved to ${screenshot}"
    RETURN    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${pdf}    ${screenshot}
    Open Pdf    ${pdf}
    ${files}=    Create List
    ...    ${screenshot}:align=center
    Add Files To Pdf    files=${files}    target_document=${pdf}    append=${True}
    Close Pdf    ${pdf}

Order another Robot
    Click Button    order-another

Archive output PDFs
    Archive Folder With Zip    ${RECEIPTS_FOLDER}    ${OUTPUT_DIR}${/}orders.zip

Close RobotSpareBin Browser
    Close Browser
