*** Settings ***
Documentation       IMDB SCENARIOS TEST CASES

Library             SeleniumLibrary
Library             Dialogs


*** Variables ***
${IMDB_URL}         https://www.imdb.com/
${BROWSER}          Edge
${MOVIE_NAME}       The Shawshank Redemption


*** Test Cases ***
Scenario 1: Verify user can search for a movie on the IMDb homepage
    Open IMDB Website
    Search Movie    ${MOVIE_NAME}
    Check Search Movie Results    ${MOVIE_NAME}
    Pause Execution

Scenario 2: Verify user can access the top-rated movies section
    Open IMDB Website
    Open Top 250 Movies Page
    Check Top 250 Movies Page    ${MOVIE_NAME}
    Pause Execution

Scenario 3: Verify user can search for movies released in a specific year on IMDb
    Open IMDB Website
    Open Advanced Title Search Page
    Apply Advanced Title Search    Feature Film    Action    2010    2020    User Rating Descending
    Check Advanced Title Search Result    Action    2010    2020
    Pause Execution


*** Keywords ***
Open IMDB Website
    Open Browser    ${IMDB_URL}    ${BROWSER}
    Maximize Browser Window

Search Movie
    [Arguments]    ${MOVIE}

    ${SEARCH_INPUT}=    Get WebElement    //input[@id="suggestion-search"]
    Input Text    ${SEARCH_INPUT}    ${MOVIE}

    ${SEARCH_BUTTON}=    Get WebElement    //button[@id="suggestion-search-button"]
    Click Button    ${SEARCH_BUTTON}

Check Search Movie Results
    [Arguments]    ${MOVIE}

    ${MOVIE_LIST}=    Get WebElements    //a[@class="ipc-metadata-list-summary-item__t"]

    FOR    ${MOVIE_IDX}    ${MOVIE_ELE}    IN ENUMERATE    @{MOVIE_LIST}
        ${MOVIE_TITLE}=    Get Text    ${MOVIE_ELE}

        IF    $MOVIE_IDX == 0
            Should Be Equal    ${MOVIE_TITLE}    ${MOVIE}    ignore_case=True
        ELSE
            Should Contain    ${MOVIE_TITLE}    ${MOVIE}    ignore_case=True
        END
    END

Open Top 250 Movies Page
    ${MENU_BUTTON}=    Get WebElement    //*[@id="imdbHeader-navDrawerOpen"]
    Click Element    ${MENU_BUTTON}

    ${TOP_250_MOVIES_LINK}=    Get WebElement
    ...    //span[contains(@class,'ipc-list-item__text') and contains(text(),'Top 250 Movies')]/..

    Click Element    ${TOP_250_MOVIES_LINK}

Check Top 250 Movies Page
    [Arguments]    ${TOP_RATED_MOVIE}

    ${TOP_250_MOVIES_LIST}=    Get WebElements    //tbody[@class="lister-list"]/tr
    Length Should Be    ${TOP_250_MOVIES_LIST}    250

    ${TOP_RATED_MOVIE_NAME}=    Get WebElement    //tbody[@class="lister-list"]/tr//td[@class="titleColumn"]/a
    ${TOP_RATED_MOVIE_NAME_TEXT}=    Get Text    ${TOP_RATED_MOVIE_NAME}
    Should Be Equal    ${TOP_RATED_MOVIE_NAME_TEXT}    ${TOP_RATED_MOVIE}    ignore_case=True

Open Advanced Title Search Page
    ${ALL_BUTTON}=    Get WebElement    //form[@id="nav-search-form"]/div
    Click Element    ${ALL_BUTTON}

    ${ADVANCED_SEARCH_LINK}=    Get WebElement
    ...    //ul[contains(@class, 'searchCatSelector ')]/a[contains(@class, "searchCatSelector__item")]
    Click Element    ${ADVANCED_SEARCH_LINK}

    ${ADVANCED_TITLE_SEARCH_LINK}=    Get WebElement
    ...    //*[contains(@class, 'imdb-search-gateway__link')]//a[contains(text(), 'Advanced Title Search')]
    Click Element    ${ADVANCED_TITLE_SEARCH_LINK}

Apply Advanced Title Search
    [Arguments]    ${TITLE_TYPE}    ${GNERES}    ${START_YEAR}    ${END_YEAR}    ${SORT_BY}

    ${TITLE_TYPE_INPUT}=    Get WebElement
    ...    //label[contains(text(), $TITLE_TYPE)]/input[@type='checkbox' and @name='title_type']/..
    Click Element    ${TITLE_TYPE_INPUT}

    ${GNERES_INPUT_FIELD}=    Get WebElement
    ...    //input[@type='checkbox' and @name='genres']/following-sibling::label[contains(text(), '${GNERES}')]
    Click Element    ${GNERES_INPUT_FIELD}

    ${START_YEAR_INPUT}=    Get WebElement    //input[@name='release_date-min']
    Input Text    ${START_YEAR_INPUT}    ${START_YEAR}

    ${END_YEAR_INPUT}=    Get WebElement    //input[@name='release_date-max']
    Input Text    ${END_YEAR_INPUT}    ${END_YEAR}

    ${SORT_BY_SELECT_BOX}=    Get WebElement    //select[@name='sort']
    Click Element    ${SORT_BY_SELECT_BOX}

    ${SORT_BY_OPTION}=    Get WebElement    //select[@name='sort']/option[contains(text(), '${SORT_BY}')]
    Click Element    ${SORT_BY_OPTION}

    ${SEARCH_BUTTON}=    Get WebElement    //form//button[contains(@class, 'primary') and contains(text(), 'Search')]
    Click Button    ${SEARCH_BUTTON}

Check Advanced Title Search Result
    [Arguments]    ${GNERES}    ${START_YEAR}    ${END_YEAR}

    ${START_YEAR}=    Convert To Integer    ${START_YEAR}
    ${END_YEAR}=    Convert To Integer    ${END_YEAR}

    ${MOVIES}=    Get WebElements    //*[@class='lister-list']/div
    ${MOVIES_COUNT}=    Get Length    ${MOVIES}

    ${PREV_MOVIE_RATING}=    Get Movie Rating    ${0}

    FOR    ${IDX}    ${MOVIE}    IN ENUMERATE    @{MOVIES}
        Log    ${MOVIE.text}

        ${MOVIE_GENER}=    Get Movie Gener    ${IDX}
        Should Contain    ${MOVIE_GENER}    ${GNERES}

        ${MOVIE_YEAR_NUM}=    Get Movie Released Year    ${IDX}
        IF    not ($START_YEAR <= $MOVIE_YEAR_NUM <= $END_YEAR)
            Fail
            ...    unexpected movie released year. the movie released year should be between ${START_YEAR} and ${END_YEAR}, but got ${MOVIE_YEAR_NUM}
        END

        ${MOVIE_RATING}=    Get Movie Rating    ${IDX}
        IF    $PREV_MOVIE_RATING < $MOVIE_RATING
            Fail    unexpected sorting, movies should be sorted by user rating descendingly
        END
        ${PREV_MOVIE_RATING}=    Set Variable    ${MOVIE_RATING}
    END

Get Movie Gener
    [Arguments]    ${MOVIE_IDX}

    ${MOVIES_GENER_ELEMENT}=    Get WebElements
    ...    //*[@class='lister-list']//span[contains(@class, 'genre')]

    ${MOVIE_GENER_ELEMENT}=    Set Variable    ${MOVIES_GENER_ELEMENT[${MOVIE_IDX}]}
    ${MOVIE_GENER_TEXT}=    Get Text    ${MOVIE_GENER_ELEMENT}

    RETURN    ${MOVIE_GENER_TEXT}

Get Movie Released Year
    [Arguments]    ${MOVIE_IDX}

    ${MOVIES_YEAR_ELEMENT}=    Get WebElements
    ...    //*[@class='lister-list']//span[contains(@class, 'lister-item-year')]

    ${MOVIE_YEAR}=    Set Variable    ${MOVIES_YEAR_ELEMENT[${MOVIE_IDX}]}
    ${MOVIE_YEAR_TEXT}=    Get Text    ${MOVIE_YEAR}
    ${MOVIE_YEAR_TEXT}=    Execute Javascript
    ...    return arguments[0].replaceAll(/\\D/g, '');
    ...    ARGUMENTS
    ...    ${MOVIE_YEAR_TEXT}
    ${MOVIE_YEAR_NUM}=    Convert To Integer    ${MOVIE_YEAR_TEXT}

    RETURN    ${MOVIE_YEAR_NUM}

Get Movie Rating
    [Arguments]    ${MOVIE_IDX}

    ${MOVIES_RATING_ELEMENT}=    Get WebElements
    ...    //*[@class='lister-list']//div[contains(@class, 'ratings-imdb-rating')]
    ${MOVIE_RATING_ELEMENT}=    Set Variable    ${MOVIES_RATING_ELEMENT[${MOVIE_IDX}]}
    ${MOVIE_RATING_TEXT}=    Get Text    ${MOVIE_RATING_ELEMENT}
    ${MOVIE_RATING}=    Convert To Number    ${MOVIE_RATING_TEXT}

    RETURN    ${MOVIE_RATING}
