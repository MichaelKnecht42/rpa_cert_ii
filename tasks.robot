*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables


*** Variables ***
${ORDER_TABLE}      ${EMPTY}


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Close the annoying modal
    Download orders
    Submit orders
    [Teardown]    Close the browser


*** Keywords ***
Open the robot order website
    Open Browser    https://robotsparebinindustries.com/#/robot-order

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
        Submit the order
        Wait Until Keyword Succeeds    3x    1s    Order another
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

Submit the order
    Click Button    //button[@id="order"]

Order another
    TRY
        Click Button    //button[@id="order-another"]
    EXCEPT
        Submit the order
        Click Button    //button[@id="order-another"]
    END
