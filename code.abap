REPORT ZTEST_JOE.

TABLES PA2001.

"WRITE:/ TEXT-001.
"ULINE.


PARAMETERS: BEGINDAT LIKE PA2001-BEGDA OBLIGATORY DEFAULT '20220706',
            ENDDAT   LIKE PA2001-ENDDA DEFAULT '20240105'.
"PRSNNLNO TYPE PA2001-PERNR OBLIGATORY DEFAULT '1393500'
"SUBTYPE  TYPE PA2001-SUBTY OBLIGATORY DEFAULT '0100' VALUE CHECK



SELECT-OPTIONS:
  PRSNNLNO FOR PA2001-PERNR OBLIGATORY NO INTERVALS DEFAULT '1393500',
  SUBTYPE FOR PA2001-SUBTY OBLIGATORY NO INTERVALS DEFAULT '0100'.

TYPES: BEGIN OF ABSENSEDATA,
         PRSNNLNO(9) TYPE C,
         SUBTYPE(4)  TYPE C,
         VALUE       TYPE I,
         "0100 Like PA2001-SUBTY,
       END OF ABSENSEDATA.

DATA: FINALRESULT TYPE TABLE OF ABSENSEDATA.

"WRITE: 'Employee personal number'.

*LOOP AT SUBTYPE.
* WRITE: SUBTYPE-LOW, '      '.
*ENDLOOP.

LOOP AT PRSNNLNO.

  DATA: LINE LIKE LINE OF FINALRESULT.


*  WRITE:/ PRSNNLNO-LOW, '      '.



  LOOP AT SUBTYPE.

    DATA : BEGIN OF RESULTS OCCURS 0.
            INCLUDE STRUCTURE PA2001.
    DATA : END OF RESULTS.

    "INITIALIZATION.

    SELECT * FROM PA2001
      WHERE  BEGDA < @ENDDAT AND ENDDA >= @BEGINDAT AND PERNR = @PRSNNLNO-LOW AND SUBTY = @SUBTYPE-LOW
      INTO TABLE @RESULTS.

    SORT RESULTS BY BEGDA ASCENDING.


    DATA:LV_DIFF     TYPE I, SUM TYPE I, TABLELENGTH TYPE I.

* Calculate table length
    TABLELENGTH = LINES( RESULTS ).


    If tablelength NE 0.
*Get the first and last value to check if they exceed their super range

    READ TABLE RESULTS INDEX 1.

    DATA: FROM TYPE DATS,
          TO   LIKE FROM.

    IF RESULTS-ENDDA > ENDDAT AND RESULTS-BEGDA < BEGINDAT.
      FROM = BEGINDAT.
      TO = ENDDAT.
    ELSEIF RESULTS-ENDDA > ENDDAT.
      FROM = RESULTS-BEGDA.
      TO = ENDDAT.
    ELSEIF RESULTS-BEGDA < BEGINDAT.
      FROM = BEGINDAT.
      TO = RESULTS-ENDDA.
    ELSE.
      FROM = RESULTS-BEGDA.
      TO = RESULTS-ENDDA.
    ENDIF.

    IF FROM EQ TO.
      SUM = SUM + 1.
    ELSE.
      CALL FUNCTION 'DAYS_BETWEEN_TWO_DATES'
        EXPORTING
          I_DATUM_BIS = TO
          I_DATUM_VON = FROM
        IMPORTING
          E_TAGE      = LV_DIFF.
      "LV_DIFF = LV_DIFF.
      SUM = SUM + LV_DIFF + 1.
    ENDIF.

* Check for the 3 posibilites for the last element
    IF TABLELENGTH NE 1.
      READ TABLE RESULTS INDEX TABLELENGTH.
      IF RESULTS-ENDDA > ENDDAT.
        FROM = RESULTS-BEGDA.
        TO = ENDDAT.
      ELSEIF RESULTS-BEGDA < BEGINDAT.
        FROM = BEGINDAT.
        TO = RESULTS-ENDDA.
      ELSE.
        FROM = RESULTS-BEGDA.
        TO = RESULTS-ENDDA.
      ENDIF.

      IF FROM EQ TO.
        SUM = SUM + 1.
      ELSE.
        CALL FUNCTION 'DAYS_BETWEEN_TWO_DATES'
          EXPORTING
            I_DATUM_BIS = TO
            I_DATUM_VON = FROM
          IMPORTING
            E_TAGE      = LV_DIFF.
        "LV_DIFF = LV_DIFF.
        SUM = SUM + LV_DIFF + 1.
      ENDIF.

      LOOP AT RESULTS FROM 2 TO TABLELENGTH - 1.
        SUM = SUM + RESULTS-ABRTG.
      ENDLOOP.
    ENDIF.
    endif.
    LINE-PRSNNLNO = PRSNNLNO-LOW.
    LINE-SUBTYPE = SUBTYPE-LOW.
    LINE-VALUE = SUM.
    APPEND LINE TO FINALRESULT.
    CLEAR SUM.
    CLEAR results.

  ENDLOOP.

ENDLOOP.

"Create the ALV and view it

CL_SALV_TABLE=>FACTORY(
  IMPORTING
    R_SALV_TABLE = DATA(LO_ALV)
  CHANGING
    T_TABLE      = FINALRESULT ).

LO_ALV->GET_FUNCTIONS( )->SET_DEFAULT( ABAP_TRUE ).
LO_ALV->GET_FUNCTIONS( )->SET_ALL( ABAP_TRUE ).


LO_ALV->DISPLAY( ).