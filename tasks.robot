*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Windows
Library             RPA.Archive


*** Variables ***
${ORDER_TABLE}                  ${EMPTY}
${PDF_FILE}                     ${EMPTY}
${PDF_RECEIPTS_FOLDER}          ${CURDIR}${/}output${/}receipts${/}
${robot_preview_file}           ${EMPTY}
${robot_preview_screenshot}     ${EMPTY}


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Download orders
    Open the robot order website
    Close the annoying modal
    Submit orders
    Create a ZIP file with the PDF receipt files
    [Teardown]    Close the browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying modal
    Click Button When Visible    //button[@class="btn btn-dark"]

Close the browser
    Close Browser

Download orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True    target_file=${CURDIR}${/}input

Submit orders
    ${ORDER_TABLE}=    Read table from CSV    ${CURDIR}${/}input${/}orders.csv    header=True
    Log    Found columns: ${ORDER_TABLE.columns}
    FOR    ${order}    IN    @{ORDER_TABLE}
        Fill the form    ${order}[Head]    ${order}[Body]    ${order}[Legs]    ${order}[Address]
        Preview the robot
        Wait Until Keyword Succeeds    5x    1s    Finalize order    ${order}[Order number]
        Close the annoying modal
    END

Fill the form
    [Arguments]    ${head}    ${body}    ${legs}    ${address}
    Select From List By Index    //select[@class="custom-select"]    ${head}
    Select Radio Button    body    ${body}
    Input Text    //input[@placeholder='Enter the part number for the legs']    ${legs}
    Input Text    //input[@placeholder='Shipping address']    ${address}

Preview the robot
    Click Button When Visible    //button[@id="preview"]

Click order button
    Click Button    //button[@id="order"]

Finalize order
    [Arguments]    ${order_number}
    Click order button
    ${PDF_FILE}=    Store the order receipt as a PDF file    ${order_number}
    Take a screenshot of the robot image and append to receipt PDF    ${order_number}    ${PDF_FILE}
    Click Button    //button[@id="order-another"]

Store the order receipt as a PDF file
    [Arguments]    ${order_number}
    ${PDF_FILE}=    Set Variable    ${PDF_RECEIPTS_FOLDER}Order_${order_number}_receipt.pdf
    Wait Until Element Is Visible    id:receipt
    ${sales_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${sales_results_html}    ${PDF_FILE}
    RETURN    ${PDF_FILE}

Take a screenshot of the robot image and append to receipt PDF
    [Arguments]    ${order_number}    ${PDF_FILE}
    ${robot_preview_file}=    Set Variable    ${CURDIR}${/}output${/}preview${/}Order_${order_number}_robot_preview.png
    ${robot_preview_screenshot}=    RPA.Browser.Selenium.Screenshot    id:robot-preview-image    ${robot_preview_file}
    ${files}=    Create List    ${robot_preview_file}
    Add Files To Pdf
    ...    ${files}
    ...    ${PDF_FILE}
    ...    ${True}

Create a ZIP file with the PDF receipt files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${PDF_RECEIPTS_FOLDER}
    ...    ${zip_file_name}
