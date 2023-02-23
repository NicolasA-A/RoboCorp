*** Settings ***
Documentation       Inhuman Insurance, Inc. Artificial Intelligence System robot.
...                 Produces traffic data work items.

Library             RPA.JSON
Library             RPA.Tables
Library             Collections
Library             OperatingSystem
Resource            shared.robot


*** Variables ***
${TRAFFIC_JSON_FILE_PATH}       ${OUTPUT_DIR}${/}traffic.json
${CSV_TABLE_TEST}               ${OUTPUT_DIR}${/}table.csv
# JSON data keys:
${COUNTRY_KEY}                  SpatialDim
${GENDER_KEY}                   Dim1
${RATE_KEY}                     NumericValue
${YEAR_KEY}                     TimeDim


*** Tasks ***
Produce traffic data work items
    Remove File    ${CSV_TABLE_TEST}
    Download traffic data
    ${traffic_data}=    Load traffic data as table
    #Write table to CSV    ${traffic_data}    ${OUTPUT_DIR}${/}table.csv
    ${filtered_data}=    Filter and sort traffic data    ${traffic_data}
    ${latest_data_by_country}=    Get latest data by country    ${filtered_data}
    ${payloads}=    Create work item payloads    ${latest_data_by_country}
    Save work item payloads    ${payloads}


*** Keywords ***
Download traffic data
    Download
    ...    https://github.com/robocorp/inhuman-insurance-inc/raw/main/RS_198.json
    ...    ${TRAFFIC_JSON_FILE_PATH}
    ...    overwrite=${True}

Load traffic data as table
    ${json}=    Load JSON from file    ${TRAFFIC_JSON_FILE_PATH}
    ${table}=    Create Table    ${json}[value]
    RETURN    ${table}

Filter and sort traffic data
    [Arguments]    ${traffic_data}
    ${max_rate}=    Set Variable    ${5.0}
    ${both_genders}=    Set Variable    BTSX
    Filter Table By Column    ${traffic_data}    ${RATE_KEY}    <    ${max_rate}
    Filter Table By Column    ${traffic_data}    ${GENDER_KEY}    ==    ${both_genders}
    Sort Table By Column    ${traffic_data}    ${YEAR_KEY}
    RETURN    ${traffic_data}

Get latest data by country
    [Arguments]    ${filtered_data}
    ${filtered_data}=    Group Table By Column    ${filtered_data}    ${COUNTRY_KEY}
    ${latest_data_by_country}=    Create List
    FOR    ${group}    IN    @{filtered_data}
        ${first_row}=    Pop Table Row    ${group}
        Append To List    ${latest_data_by_country}    ${first_row}
    END
    RETURN    ${latest_data_by_country}

Create work item payloads
    [Arguments]    ${latest_data_by_country}
    ${payloads}=    Create List
    FOR    ${row}    IN    @{latest_data_by_country}
        ${payload}=
        ...    Create Dictionary
        ...    country=${row}[${COUNTRY_KEY}]
        ...    year=${row}[${YEAR_KEY}]
        ...    rate=${row}[${RATE_KEY}]
        Append To List    ${payloads}    ${payload}
    END
    RETURN    ${payloads}

Save work item payloads
    [Arguments]    ${payloads}
    FOR    ${payload}    IN    @{payloads}
        Save work item payload    ${payload}
    END

Save work item payload
    [Arguments]    ${payload}
    ${variables}=    Create Dictionary    ${WORK_ITEM_NAME}=${payload}
    Create Output Work Item    variables=${variables}    save=True
