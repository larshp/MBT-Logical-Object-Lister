CLASS /mbtools/cl_bw_tlogo_lister DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

************************************************************************
* MBT Logical Object Lister
*
* Copyright 2021 Marc Bernard <https://marcbernardtools.com/>
* SPDX-License-Identifier: GPL-3.0-only
************************************************************************
  PUBLIC SECTION.

    TYPES ty_tlogos TYPE RANGE OF rstlogoprop-tlogo.

    CONSTANTS c_ujt_invisible_types TYPE funcname VALUE 'UJT_TLOGO_TYPE_DETAILS' ##NO_TEXT.

    METHODS initialize
      IMPORTING
        !ir_tlogos TYPE ty_tlogos
        !iv_bw     TYPE abap_bool
        !iv_b4h    TYPE abap_bool
        !iv_bw4    TYPE abap_bool
        !iv_prop   TYPE abap_bool
        !iv_bytext TYPE abap_bool
        !iv_byname TYPE abap_bool
        !iv_bysequ TYPE abap_bool
        !iv_cache  TYPE abap_bool
        !iv_subobj TYPE abap_bool
        !iv_bpc    TYPE abap_bool.
    METHODS pbo.
    METHODS pai
      CHANGING
        !cv_ok_code TYPE sy-ucomm.
    METHODS screen.
  PROTECTED SECTION.

  PRIVATE SECTION.

    " Can't use APD types since they don't exist in SAP BW/4HANA anymore
    TYPES:
      BEGIN OF ty_s_tool,
        tool                TYPE c LENGTH 30, "rsant_fct_tool-tool,
        tool_image          TYPE c LENGTH 80, "rsant_fct_tool-tool_image,
        toolgroup           TYPE c LENGTH 30, "rsant_fct_tool-tool_group,
        show_property_popup TYPE c LENGTH 1,  "rsant_fct_tool-show_popup,
        classid             TYPE c LENGTH 30, "rsant_fct_tool-classid,
        classid_modifier    TYPE c LENGTH 60, "rsant_fct_tool-classid_modifier,
        text                TYPE c LENGTH 20, "rsant_fct_toolt-text,
        tooltip             TYPE c LENGTH 80, "rsant_fct_toolt-tooltip,
      END OF ty_s_tool.

    TYPES:
      BEGIN OF ty_s_appltool,
        field_order TYPE i. "rsant_wb_typec-field_order
        INCLUDE TYPE ty_s_tool AS s_tool."cl_rsan_fct_tool=>ys_tool
    TYPES:
      END OF ty_s_appltool.
    TYPES ty_ts_appltool TYPE SORTED TABLE OF ty_s_appltool
                                 WITH NON-UNIQUE KEY field_order.

    TYPES:
      BEGIN OF ty_s_appltoolgroup,
        toolgroup   TYPE c LENGTH 30, "rsant_fct_toog-toolgroup,
        ts_applfunc TYPE ty_ts_appltool,
        tool_order  TYPE i, "rsant_fct_toog-tool_order,
        text        TYPE c LENGTH 20, "rsant_fct_toogt-text,
        tooltip     TYPE c LENGTH 80, "rsant_fct_toogt-tooltip,
      END OF ty_s_appltoolgroup.

    DATA mo_tree TYPE REF TO /mbtools/cl_tree.
    DATA mr_tlogos TYPE ty_tlogos.
    DATA mv_bw TYPE abap_bool  ##NEEDED.
    DATA mv_b4h TYPE abap_bool.
    DATA mv_bw4 TYPE abap_bool.
    DATA mv_prop TYPE abap_bool.
    DATA mv_bytext TYPE abap_bool.
    DATA mv_byname TYPE abap_bool.
    DATA mv_bysequ TYPE abap_bool.
    DATA mv_cache TYPE abap_bool.
    DATA mv_subobj TYPE abap_bool.
    DATA mv_bpc TYPE abap_bool.
    DATA mt_tree TYPE rsawbn_t_tree  ##NEEDED.
    DATA mt_tlogo TYPE rs_t_tlogo.
    DATA mt_bpc TYPE rs_t_tlogo.
    DATA mt_blacklist TYPE rs_t_tlogo.

    METHODS _check_b4h_mode
      CHANGING
        !co_level  TYPE REF TO /mbtools/cl_tree_level
        !cv_hidden TYPE abap_bool.
    METHODS _prepare_tree.
    METHODS _main
      IMPORTING
        !iv_tlogo   TYPE rstlogo
        !iv_domname TYPE domname
        !iv_level   TYPE i.
    METHODS _icon
      IMPORTING
        !iv_icon  TYPE icon_d
        !iv_level TYPE i.
    METHODS _properties
      IMPORTING
        !iv_tlogo TYPE rstlogo
        !iv_icon  TYPE icon_d
        !iv_text  TYPE rstxtlg
        !iv_level TYPE i.
    METHODS _anpr
      IMPORTING
        !iv_level TYPE i.
    METHODS _anpr_group
      IMPORTING
        !is_group TYPE ty_s_appltoolgroup
        !iv_level TYPE i.
    METHODS _anpr_tool
      IMPORTING
        !is_tool  TYPE ty_s_appltool
        !iv_level TYPE i.
    METHODS _rspv
      IMPORTING
        !iv_level TYPE i.
    METHODS _rspv_category
      IMPORTING
        !is_category TYPE rspccategory
        !iv_level    TYPE i.
    METHODS _rspv_type
      IMPORTING
        !is_variant TYPE rsprocesstypes
        !iv_level   TYPE i.
    METHODS _write_table
      IMPORTING
        !iv_table TYPE tabname
        !iv_title TYPE rstxtlg
        !iv_level TYPE i.
    METHODS _write_function
      IMPORTING
        !iv_funct TYPE funcname
        !iv_title TYPE rstxtlg
        !iv_level TYPE i.
    METHODS _write_class
      IMPORTING
        !iv_class TYPE seoclsname
        !iv_title TYPE rstxtlg
        !iv_level TYPE i.
    METHODS _prepare_tlogo_blacklist.
ENDCLASS.



CLASS /mbtools/cl_bw_tlogo_lister IMPLEMENTATION.


  METHOD initialize.

    CREATE OBJECT mo_tree.

    mr_tlogos = ir_tlogos.
    mv_bw      = iv_bw.
    mv_b4h     = iv_b4h.
    mv_bw4     = iv_bw4.
    mv_prop    = iv_prop.
    mv_bytext  = iv_bytext.
    mv_byname  = iv_byname.
    mv_bysequ  = iv_bysequ.
    mv_cache   = iv_cache.
    mv_subobj  = iv_subobj.
    mv_bpc     = iv_bpc.

    mo_tree->add_top_node(
      iv_icon  = icon_folder
      iv_title = 'BW Logical Objects'(001) ).

    " Prepare processing
    _prepare_tree( ).

    _prepare_tlogo_blacklist( ).

    " Process sub nodes
    _main(
      iv_tlogo   = ''
      iv_domname = 'RSTLOGO'
      iv_level   = 1 ).

    " Expand complete tree
    mo_tree->expand_all( ).

  ENDMETHOD.


  METHOD pai.

    mo_tree->pai( cv_ok_code ).

    CLEAR cv_ok_code.

  ENDMETHOD.


  METHOD pbo.

    SET PF-STATUS 'MAIN' OF PROGRAM sy-cprog.
    SET TITLEBAR 'MAIN' OF PROGRAM sy-cprog.

    mo_tree->display( ).

  ENDMETHOD.


  METHOD screen.

    DATA:
      lv_rel TYPE cvers-release,
      lv_bpc TYPE abap_bool,
      lv_bw4 TYPE abap_bool.

    " Is BPC available?
    CALL FUNCTION 'FUNCTION_EXISTS'
      EXPORTING
        funcname           = c_ujt_invisible_types
      EXCEPTIONS
        function_not_exist = 1
        OTHERS             = 2.
    lv_bpc = boolc( sy-subrc = 0 ).

    " Is this BW4?
    SELECT SINGLE release FROM cvers INTO lv_rel WHERE component = 'DW4CORE'.
    lv_bw4 = boolc( sy-subrc = 0 ).

    LOOP AT SCREEN.
      IF screen-group1 = 'BPC' AND lv_bpc = abap_false.
        screen-input = '0'.
      ENDIF.
      IF screen-group1 = 'BW4' AND lv_bw4 = abap_true.
        screen-input = '0'.
      ENDIF.
      MODIFY SCREEN.
    ENDLOOP.

  ENDMETHOD.


  METHOD _anpr.

    DATA:
      lo_appl  TYPE REF TO object, "cl_rsan_fct_appl_type,
      ls_group TYPE ty_s_appltoolgroup.

    FIELD-SYMBOLS:
      <lt_appltoolgroups> TYPE ANY TABLE,
      <ls_group>          TYPE any.

    TRY.
        CALL METHOD ('CL_RSAN_FCT_APPL_TYPE')=>get_appl_type
          EXPORTING
            i_appl_type = 'GENERIC'
          RECEIVING
            r_appl_type = lo_appl.

        ASSIGN lo_appl->('TH_APPLTOOLGROUPS') TO <lt_appltoolgroups>.
        CHECK sy-subrc = 0.

        LOOP AT <lt_appltoolgroups> ASSIGNING <ls_group>.
          MOVE-CORRESPONDING <ls_group> TO ls_group.

          _anpr_group(
            is_group = ls_group
            iv_level = iv_level ).

        ENDLOOP.
      CATCH cx_root ##NO_HANDLER.
        " APD does not exist here
    ENDTRY.

  ENDMETHOD.


  METHOD _anpr_group.

    DATA:
      lo_level    TYPE REF TO /mbtools/cl_tree_level,
      lt_applfunc TYPE STANDARD TABLE OF ty_s_appltool WITH DEFAULT KEY,
      ls_tool     TYPE ty_s_appltool,
      lv_hidden   TYPE abap_bool.

    CREATE OBJECT lo_level
      EXPORTING
        io_tree  = mo_tree
        iv_level = iv_level.

    lo_level->text = is_group-text.

    CASE is_group-toolgroup.
      WHEN 'DS'.
        lo_level->icon = icon_bw_apd_target.
      WHEN 'DST'.
        lo_level->icon = icon_bw_apd_transformation.
      WHEN 'DT'.
        lo_level->icon = icon_bw_apd_source.
      WHEN OTHERS.
        " Something must be new in APD
        ASSERT 0 = 1.
    ENDCASE.

    _check_b4h_mode(
      CHANGING
        co_level  = lo_level
        cv_hidden = lv_hidden ).

    mo_tree->add_detail(
      iv_icon   = lo_level->icon
      iv_title  = 'Tool Group'(002)
      iv_text   = lo_level->text
      iv_value  = is_group-toolgroup
      iv_level  = lo_level->level
      iv_hidden = lv_hidden ).

    lo_level->next( ).

    lt_applfunc = is_group-ts_applfunc.

    CASE abap_true.
      WHEN mv_bytext.
        SORT lt_applfunc BY text.
      WHEN mv_byname.
        SORT lt_applfunc BY tool.
        "WHEN mv_bysequ
        " keep it
    ENDCASE.

    LOOP AT lt_applfunc INTO ls_tool.

      _anpr_tool(
        is_tool  = ls_tool
        iv_level = lo_level->level ).

    ENDLOOP.

    lo_level->back( ).

  ENDMETHOD.


  METHOD _anpr_tool.

    DATA:
      lo_level  TYPE REF TO /mbtools/cl_tree_level,
      ls_tool   LIKE is_tool,
      lv_hidden TYPE abap_bool.

    CREATE OBJECT lo_level
      EXPORTING
        io_tree  = mo_tree
        iv_level = iv_level.

    ls_tool = is_tool.

    REPLACE '.GIF' WITH '' INTO ls_tool-tool_image.
    IF ls_tool-tool_image CS '/SAP/PUBLIC/BC/ICONS/'.
      REPLACE '/SAP/PUBLIC/BC/ICONS/S_' WITH '' INTO ls_tool-tool_image.
      CONDENSE ls_tool-tool_image NO-GAPS.
    ELSEIF ls_tool-tool_image CS '/SAP/BW/EI/APD/ICONS/'.
      REPLACE '/SAP/BW/EI/APD/ICONS/' WITH '' INTO ls_tool-tool_image.
      CONDENSE ls_tool-tool_image NO-GAPS.

      CASE ls_tool-tool_image.
        WHEN 'BWDATABASETABLE'.
          ls_tool-tool_image = 'BWDATA'.
        WHEN 'BWASSOCIATIONANALYSIS'.
          ls_tool-tool_image = 'BWASAN'.
        WHEN 'BWCLUSTERANALYSIS'.
          ls_tool-tool_image = 'BWCLUS'.
        WHEN 'BWCOLUMNTOROW'.
          ls_tool-tool_image = 'BWCORO'.
        WHEN 'BWDATAMINING'.
          ls_tool-tool_image = 'BWDMTH'.
        WHEN 'BWDECISIONTREE'.
          ls_tool-tool_image = 'BWDETR'.
        WHEN 'BWREGRESSIONANALYSIS'.
          ls_tool-tool_image = 'BWREGR'.
        WHEN 'BWROWTOCOLUMN'.
          ls_tool-tool_image = 'BWROCO'.
        WHEN 'BWSOURCECRM'.
          ls_tool-tool_image = 'B_BWSG'.
        WHEN 'BWWEIGHTEDSCORETABLE'.
          ls_tool-tool_image = 'BWWSTA'.
        WHEN 'DST_REGRESSION'.
          ls_tool-tool_image = 'BWREGR'.
        WHEN OTHERS.
          ls_tool-tool_image = ''.
      ENDCASE.
    ENDIF.
    CONCATENATE '@' ls_tool-tool_image(6) '@' INTO ls_tool-tool_image.
    CONDENSE ls_tool-tool_image NO-GAPS.

    SELECT SINGLE id FROM icon INTO lo_level->icon
      WHERE internal = ls_tool-tool_image ##WARN_OK.
    IF sy-subrc <> 0.
      lo_level->icon = ''.
    ENDIF.

    lo_level->text = ls_tool-text.

    _check_b4h_mode(
       CHANGING
         co_level  = lo_level
         cv_hidden = lv_hidden ).

    mo_tree->add_detail(
      iv_icon   = lo_level->icon
      iv_title  = 'Tool'(003)
      iv_text   = lo_level->text
      iv_value  = ls_tool-tool
      iv_level  = lo_level->level
      iv_hidden = lv_hidden ).

    IF mv_prop = abap_true.
      _icon(
        iv_icon  = lo_level->icon
        iv_level = lo_level->level ).
    ENDIF.

    lo_level->back( ).

  ENDMETHOD.


  METHOD _check_b4h_mode.

    IF mv_b4h = abap_true.
      co_level->text = co_level->text && ` ` && '[not supported in B4H mode]'(010).
      co_level->icon = icon_dummy.
      cv_hidden      = abap_true.
    ENDIF.

  ENDMETHOD.


  METHOD _icon.

    DATA lo_level TYPE REF TO /mbtools/cl_tree_level.

    CREATE OBJECT lo_level
      EXPORTING
        io_tree  = mo_tree
        iv_level = iv_level.

    " Icon
    SELECT SINGLE id name FROM icon INTO (lo_level->value, lo_level->text)
      WHERE id = iv_icon.
    IF sy-subrc = 0.
      mo_tree->add_detail(
        iv_icon  = iv_icon
        iv_title = 'Icon'(004)
        iv_text  = lo_level->text
        iv_value = lo_level->value
        iv_level = lo_level->level
        iv_type  = /mbtools/if_objects=>c_icon ).
    ENDIF.

  ENDMETHOD.


  METHOD _main.

    DATA:
      lo_level   TYPE REF TO /mbtools/cl_tree_level,
      ls_value   TYPE /mbtools/cl_sap=>ty_domain_value,
      lt_value   TYPE /mbtools/cl_sap=>ty_domain_values,
      lv_title   TYPE c LENGTH 80,
      lv_hidden  TYPE rs_bool,
      lv_no_b4h  TYPE rs_bool,
      lv_dummy   TYPE icon_d,
      lv_tlogo   TYPE rstlogo,
      lv_rstxtlg TYPE rstxtlg,
      lv_iobjtp  TYPE rsd_iobjtp,
      lv_deftp   TYPE rzd1_deftp,
      lv_srctype TYPE rsa_srctype.

    CREATE OBJECT lo_level
      EXPORTING
        io_tree  = mo_tree
        iv_level = iv_level.

    " Check if domain has value table
    IF iv_domname IS NOT INITIAL.
      lt_value = /mbtools/cl_sap=>get_values_from_domain( iv_domname ).
    ENDIF.

    " Additional cases (missing in domain values)
    CASE iv_tlogo.
*      WHEN rs_c_tlogo-infocube
*      ls_value-domvalue_l = rsd_c_cubetype-spo
*      ls_value-valpos     = '0100'
*      ls_value-ddtext     = 'Semantic Partitioned Object'
*      COLLECT ls_value INTO lt_value
*      WHEN rs_c_tlogo-infoobject
*      ls_value-domvalue_l = rsd_c_objtp-attribute
*      ls_value-valpos     = '0100'
*      ls_value-ddtext     = 'Attribute'
*      COLLECT ls_value INTO lt_value
*      ls_value-domvalue_l = rsd_c_objtp-meta
*      ls_value-valpos     = '0101'
*      ls_value-ddtext     = 'Meta-InfoObject'
*      COLLECT ls_value INTO lt_value
      WHEN rs_c_tlogo-element.
        ls_value-domvalue_l = rzd1_c_deftp-sheet.
        ls_value-valpos     = '0100'.
        ls_value-ddtext     = 'Sheet'(020).
        COLLECT ls_value INTO lt_value.
        ls_value-domvalue_l = rzd1_c_deftp-cell.
        ls_value-valpos     = '0101'.
        ls_value-ddtext     = 'Cell'(021).
        COLLECT ls_value INTO lt_value.
        ls_value-domvalue_l = rzd1_c_deftp-exception.
        ls_value-valpos     = '0102'.
        ls_value-ddtext     = 'Exception'(022).
        COLLECT ls_value INTO lt_value.
        ls_value-domvalue_l = rzd1_c_deftp-condition.
        ls_value-valpos     = '0103'.
        ls_value-ddtext     = 'Condition'(023).
        COLLECT ls_value INTO lt_value.
      WHEN ''.
        " Skip non-BW objects
        DELETE lt_value WHERE domvalue_l = 'DDLS' OR domvalue_l = 'ENHO'.

        LOOP AT lt_value INTO ls_value.
          " Rename SAP InfoSets to avoid confusion with BW InfoSets
          IF ls_value-domvalue_l BETWEEN 'AQ' AND 'AQZZ'.
            CONCATENATE 'SAP' ls_value-ddtext INTO ls_value-ddtext SEPARATED BY space.
          ENDIF.
          " Rename BPC objects with prefix
          READ TABLE mt_bpc TRANSPORTING NO FIELDS
            WITH TABLE KEY tlogo = ls_value-domvalue_l.
          IF sy-subrc = 0 AND ls_value-ddtext NP 'BPC*'.
            CONCATENATE 'BPC' ls_value-ddtext INTO ls_value-ddtext SEPARATED BY space.
          ENDIF.
          " Adjust 3.x text
          IF ( ls_value-domvalue_l = 'ITEM' OR ls_value-domvalue_l = 'TMPL' ) AND
               ls_value-ddtext CS 'Format SAP BW'.
            REPLACE 'Format SAP BW 3.x' IN ls_value-ddtext WITH '3.x'.
          ENDIF.
          " Remove 3.x prefix
          IF ( ls_value-domvalue_l = 'ISFS' OR ls_value-domvalue_l = 'ISTD' ) AND
               ls_value-ddtext(3) = '3.x'.
            ls_value-ddtext = ls_value-ddtext+4(*).
          ENDIF.
          " Add 3.x suffix
          IF ( ls_value-domvalue_l = 'ISFS' OR ls_value-domvalue_l = 'ISTD' OR
               ls_value-domvalue_l = 'ISMP' OR ls_value-domvalue_l = 'ISTS' OR
               ls_value-domvalue_l = 'UPDR' ) AND ls_value-ddtext NS '3.x'.
            CONCATENATE ls_value-ddtext '(3.x)' INTO ls_value-ddtext SEPARATED BY space.
          ENDIF.
          MODIFY TABLE lt_value FROM ls_value.
        ENDLOOP.
    ENDCASE.

    " Sort by description, technical name, or transport order
    CASE abap_true.
      WHEN mv_bytext.
        SORT lt_value BY ddtext.
      WHEN mv_byname.
        SORT lt_value BY domvalue_l.
      WHEN mv_bysequ.
        SORT lt_value BY valpos.
    ENDCASE.

    LOOP AT lt_value INTO ls_value.

      IF iv_tlogo IS INITIAL.
        CHECK ls_value-domvalue_l IN mr_tlogos.
      ENDIF.

      lo_level->value = ls_value-domvalue_l.
      lo_level->text  = ls_value-ddtext.

      " Clean-up some texts
      IF lo_level->text IS INITIAL.
        lo_level->text = 'No text'(011).
      ELSEIF lo_level->text CS '(->'.
        SPLIT lo_level->text AT '(' INTO lo_level->text lv_dummy.
      ELSEIF lo_level->text CS 'Configuration for'(012).
        REPLACE 'Configuration for'(012) WITH '' INTO lo_level->text.
      ENDIF.

      " Get icon
      CASE iv_tlogo.
        WHEN rs_c_tlogo-infocube.
          lv_title = 'Sub-object'(006).

          lo_level->icon = /mbtools/cl_tlogo=>get_tlogo_icon(
            iv_tlogo     = iv_tlogo
            iv_tlogo_sub = lo_level->value ).

          lv_rstxtlg = cl_rso_repository=>get_tlogo_description( rs_c_tlogo-infocube ).

        WHEN rs_c_tlogo-infoobject.
          lv_title = 'Sub-object'(006).

          lo_level->icon = /mbtools/cl_tlogo=>get_tlogo_icon(
            iv_tlogo     = iv_tlogo
            iv_tlogo_sub = lo_level->value ).

          lv_rstxtlg = cl_rso_repository=>get_tlogo_description(
            i_tlogo  = rs_c_tlogo-infoobject
            i_iobjtp = lv_iobjtp ).

        WHEN rs_c_tlogo-element.
          lv_title = 'Sub-object'(006).

          lo_level->icon = /mbtools/cl_tlogo=>get_tlogo_icon(
            iv_tlogo     = iv_tlogo
            iv_tlogo_sub = lo_level->value ).

          lv_rstxtlg = cl_rso_repository=>get_tlogo_description(
            i_tlogo              = rs_c_tlogo-element
            i_query_element_type = lv_deftp ).

        WHEN rs_c_tlogo-logsys.
          lv_title = 'Sub-object'(006).

          lo_level->icon = /mbtools/cl_tlogo=>get_tlogo_icon(
            iv_tlogo     = iv_tlogo
            iv_tlogo_sub = lo_level->value ).

          lv_rstxtlg = cl_rsar_srctype=>get_description( lv_srctype ).

        WHEN OTHERS.
          lv_title = 'Object'(005).
          lv_tlogo = lo_level->value.

          lo_level->icon = /mbtools/cl_tlogo=>get_tlogo_icon( lv_tlogo ).

          lv_rstxtlg = cl_rso_repository=>get_tlogo_description( lv_tlogo ).

      ENDCASE.

      " Check for hidden, local or obsolete objects
      CLEAR lv_hidden.

      IF lv_tlogo IS NOT INITIAL.
        READ TABLE mt_bpc TRANSPORTING NO FIELDS
          WITH TABLE KEY tlogo = lv_tlogo.
        IF sy-subrc = 0.
          IF mv_bpc = abap_false.
            CONTINUE.
          ENDIF.
          lv_hidden = abap_true.
          lo_level->text = lo_level->text && ` ` && '[hidden]'(008).
        ELSE.
          READ TABLE mt_tlogo TRANSPORTING NO FIELDS
            WITH TABLE KEY tlogo = lv_tlogo.
          IF sy-subrc <> 0.
            lo_level->text = lo_level->text && ` ` && '[local]'(009).
          ENDIF.
        ENDIF.
      ENDIF.

      " Check mode and compatibility
      CASE abap_true.
        WHEN mv_b4h.
          " B4H Mode
          CLEAR lv_no_b4h.

          CASE iv_tlogo.
            WHEN rs_c_tlogo-infocube.
              lv_no_b4h = abap_true.
            WHEN rs_c_tlogo-logsys.
              IF lo_level->value NA 'OHF'. "ODP, HANA, File
                lv_no_b4h = abap_true.
              ENDIF.
            WHEN OTHERS.
              READ TABLE mt_blacklist TRANSPORTING NO FIELDS
                WITH TABLE KEY tlogo = lv_tlogo.
              IF sy-subrc = 0.
                lv_no_b4h = abap_true.
              ENDIF.
          ENDCASE.

          IF lv_no_b4h = abap_true.
            _check_b4h_mode(
              CHANGING
                co_level  = lo_level
                cv_hidden = lv_hidden ).
          ENDIF.

        WHEN mv_bw4.
          " SAP BW/4HANA Mode
          CASE iv_tlogo.
            WHEN rs_c_tlogo-logsys.
              IF lo_level->value NA 'OHF'. "ODP, HANA, File
                CONTINUE. ">>>
              ENDIF.
            WHEN OTHERS.
              READ TABLE mt_blacklist TRANSPORTING NO FIELDS
                WITH TABLE KEY tlogo = lv_tlogo.
              IF sy-subrc = 0.
                CONTINUE. ">>>
              ENDIF.
          ENDCASE.

      ENDCASE.

      " Add to output
      mo_tree->add_detail(
        iv_icon   = lo_level->icon
        iv_title  = lv_title
        iv_text   = lo_level->text
        iv_value  = lo_level->value
        iv_hidden = lv_hidden
        iv_level  = lo_level->level ).

      " Reset cache
      IF mv_cache IS INITIAL.
        CASE iv_tlogo.
          WHEN rs_c_tlogo-infocube.
            cl_rso_repository=>get_tlogo_icon(
              i_tlogo    = 'ZZZZ'
              i_cubetype = 'Z' ).

          WHEN rs_c_tlogo-infoobject.
            cl_rso_repository=>get_tlogo_icon(
              i_tlogo  = 'ZZZZ'
              i_iobjtp = 'ZZZ' ).

          WHEN rs_c_tlogo-element.
            cl_rso_repository=>get_tlogo_icon(
              i_tlogo              = 'ZZZZ'
              i_query_element_type = 'ZZZ' ).

          WHEN OTHERS.
            cl_rso_repository=>get_tlogo_icon( i_tlogo = 'ZZZZ' ).

        ENDCASE.
      ENDIF.

      lo_level->next( ).

      IF mv_prop = abap_true.
        IF lv_tlogo IS INITIAL.
          _icon(
            iv_icon  = lo_level->icon
            iv_level = lo_level->level ).
        ELSE.
          _properties(
            iv_tlogo = lv_tlogo
            iv_icon  = lo_level->icon
            iv_text  = lv_rstxtlg
            iv_level = lo_level->level ).
        ENDIF.
      ENDIF.

      IF mv_subobj = abap_true.
        CASE lv_tlogo.
          WHEN rs_c_tlogo-infocube.
            _main(
              iv_tlogo   = lv_tlogo
              iv_domname = 'RSCUBETYPE'
              iv_level   = lo_level->level ).
          WHEN rs_c_tlogo-infoobject.
            _main(
              iv_tlogo   = lv_tlogo
              iv_domname = 'RSIOBJTP'
              iv_level   = lo_level->level ).
          WHEN rs_c_tlogo-element.
            _main(
              iv_tlogo   = lv_tlogo
              iv_domname = 'RSZDEFTP'
              iv_level   = lo_level->level ).
          WHEN rs_c_tlogo-logsys.
            _main(
              iv_tlogo   = lv_tlogo
              iv_domname = 'RSSRCTYPE_BW'
              iv_level   = lo_level->level ).
          WHEN rs_c_tlogo-process_variant.
            _rspv( lo_level->level ).
          WHEN rs_c_tlogo-analysis_process.
            _anpr( lo_level->level ).
        ENDCASE.
      ENDIF.

      lo_level->back( ).

    ENDLOOP.

  ENDMETHOD.


  METHOD _prepare_tlogo_blacklist.

    " See BW 7.50: CL_RS_B4HANA_UTIL=>_FILL_TLOGO_BLACKLIST
    APPEND 'AGGR' TO mt_blacklist.
    APPEND 'DAGR' TO mt_blacklist.
    APPEND 'ANMO' TO mt_blacklist.
    APPEND 'DANM' TO mt_blacklist.
    APPEND 'ANPR' TO mt_blacklist.
    APPEND 'DANP' TO mt_blacklist.
    APPEND 'ANSO' TO mt_blacklist.
    APPEND 'DANS' TO mt_blacklist.
    APPEND 'AABC' TO mt_blacklist.
    APPEND 'AADT' TO mt_blacklist.
    APPEND 'AAPP' TO mt_blacklist.
    APPEND 'AAPS' TO mt_blacklist.
    APPEND 'ABPC' TO mt_blacklist.
    APPEND 'ABPF' TO mt_blacklist.
    APPEND 'ABRU' TO mt_blacklist.
    APPEND 'ACGA' TO mt_blacklist.
    APPEND 'ACGP' TO mt_blacklist.
    APPEND 'ACGS' TO mt_blacklist.
    APPEND 'ACLB' TO mt_blacklist.
    APPEND 'ACTR' TO mt_blacklist.
    APPEND 'ADAF' TO mt_blacklist.
    APPEND 'ADEE' TO mt_blacklist.
    APPEND 'ADEI' TO mt_blacklist.
    APPEND 'ADEL' TO mt_blacklist.
    APPEND 'ADIM' TO mt_blacklist.
    APPEND 'ADMC' TO mt_blacklist.
    APPEND 'ADMD' TO mt_blacklist.
    APPEND 'ADMF' TO mt_blacklist.
    APPEND 'ADMG' TO mt_blacklist.
    APPEND 'ADML' TO mt_blacklist.
    APPEND 'ADMP' TO mt_blacklist.
    APPEND 'ADMS' TO mt_blacklist.
    APPEND 'ADTG' TO mt_blacklist.
    APPEND 'AFLC' TO mt_blacklist.
    APPEND 'AFLD' TO mt_blacklist.
    APPEND 'AFLE' TO mt_blacklist.
    APPEND 'AFLG' TO mt_blacklist.
    APPEND 'AJUT' TO mt_blacklist.
    APPEND 'AKPI' TO mt_blacklist.
    APPEND 'AMBR' TO mt_blacklist.
    APPEND 'ARTP' TO mt_blacklist.
    APPEND 'ASPD' TO mt_blacklist.
    APPEND 'ASPF' TO mt_blacklist.
    APPEND 'ASPR' TO mt_blacklist.
    APPEND 'ATEM' TO mt_blacklist.
    APPEND 'ATPF' TO mt_blacklist.
    APPEND 'AWSS' TO mt_blacklist.
    APPEND 'BAOE' TO mt_blacklist.
    APPEND 'BITM' TO mt_blacklist.
    APPEND 'DBIT' TO mt_blacklist.
    APPEND 'BIXP' TO mt_blacklist.
    APPEND 'DBIX' TO mt_blacklist.
    APPEND 'BRSE' TO mt_blacklist.
    APPEND 'DBRS' TO mt_blacklist.
    APPEND 'BTMP' TO mt_blacklist.
    APPEND 'DBTM' TO mt_blacklist.
    APPEND 'CRWB' TO mt_blacklist.
    APPEND 'DCRW' TO mt_blacklist.
    APPEND 'CUBE' TO mt_blacklist.
    APPEND 'DCUB' TO mt_blacklist.
    APPEND 'DDAS' TO mt_blacklist.
    APPEND 'DDDA' TO mt_blacklist.
    APPEND 'DMMO' TO mt_blacklist.
    APPEND 'DDMM' TO mt_blacklist.
    APPEND 'ENHO' TO mt_blacklist.
    APPEND 'ERPT' TO mt_blacklist.
    APPEND 'DRPT' TO mt_blacklist.
    APPEND 'HIER' TO mt_blacklist.
    APPEND 'DHIE' TO mt_blacklist.
    APPEND 'HYBR' TO mt_blacklist.
    APPEND 'DHYB' TO mt_blacklist.
    APPEND 'INSP' TO mt_blacklist.
    APPEND 'IOBC' TO mt_blacklist.
    APPEND 'DIOC' TO mt_blacklist.
    APPEND 'ISCS' TO mt_blacklist.
    APPEND 'DSCS' TO mt_blacklist.
    APPEND 'ISET' TO mt_blacklist.
    APPEND 'DISE' TO mt_blacklist.
    APPEND 'ISFS' TO mt_blacklist.
    APPEND 'SHFS' TO mt_blacklist.
    APPEND 'ISIG' TO mt_blacklist.
    APPEND 'DISG' TO mt_blacklist.
    APPEND 'SHIG' TO mt_blacklist.
    APPEND 'ISIP' TO mt_blacklist.
    APPEND 'SHIP' TO mt_blacklist.
    APPEND 'ISMP' TO mt_blacklist.
    APPEND 'SHMP' TO mt_blacklist.
    APPEND 'ISTD' TO mt_blacklist.
    APPEND 'DSTD' TO mt_blacklist.
    APPEND 'ISTS' TO mt_blacklist.
    APPEND 'SHTR' TO mt_blacklist.
    APPEND 'ITEM' TO mt_blacklist.
    APPEND 'DITM' TO mt_blacklist.
    APPEND 'KPCE' TO mt_blacklist.
    APPEND 'DKPC' TO mt_blacklist.
    APPEND 'KPDF' TO mt_blacklist.
    APPEND 'DKPD' TO mt_blacklist.
    APPEND 'LPOA' TO mt_blacklist.
    APPEND 'LPOD' TO mt_blacklist.
    APPEND 'MPRO' TO mt_blacklist.
    APPEND 'DMPR' TO mt_blacklist.
    APPEND 'ODPE' TO mt_blacklist.
    APPEND 'ODSO' TO mt_blacklist.
    APPEND 'DODS' TO mt_blacklist.
    APPEND 'RAPA' TO mt_blacklist.
    APPEND 'RASE' TO mt_blacklist.
    APPEND 'PSA ' TO mt_blacklist.
    APPEND 'SPOK' TO mt_blacklist.
    APPEND 'THEM' TO mt_blacklist.
    APPEND 'THED' TO mt_blacklist.
    APPEND 'TMPL' TO mt_blacklist.
    APPEND 'DTMP' TO mt_blacklist.
    APPEND 'UPDR' TO mt_blacklist.
    APPEND 'DUPD' TO mt_blacklist.
    APPEND 'WWIB' TO mt_blacklist.
    APPEND 'DWIB' TO mt_blacklist.
    APPEND 'WWPA' TO mt_blacklist.
    APPEND 'DWPA' TO mt_blacklist.
    APPEND 'XCLS' TO mt_blacklist.
    APPEND 'DXCL' TO mt_blacklist.
    APPEND 'XLWB' TO mt_blacklist.
    APPEND 'DXLW' TO mt_blacklist.
    APPEND 'RDAC' TO mt_blacklist.
    APPEND 'EREL' TO mt_blacklist.

  ENDMETHOD.


  METHOD _prepare_tree.

    DATA lo_tree_model TYPE REF TO cl_rsawbn_tree_model_fl_lsys.

    " Get all TLOGOs (except for old CompositeProvider which is local only)
    SELECT tlogo FROM rstlogoprop INTO TABLE mt_tlogo
      WHERE tlogo <> 'COPR'.
    ASSERT sy-subrc = 0.

    " Get hidden BPC TLOGOs
    CALL FUNCTION 'FUNCTION_EXISTS'
      EXPORTING
        funcname           = c_ujt_invisible_types
      EXCEPTIONS
        function_not_exist = 1
        OTHERS             = 2.
    IF sy-subrc = 0.
      CALL FUNCTION c_ujt_invisible_types
        IMPORTING
          e_t_tlogo_invisible = mt_bpc.
    ENDIF.

    " Get tree model (for future use)
    CREATE OBJECT lo_tree_model.

    lo_tree_model->create_tree( ).
    lo_tree_model->set_view( 'M' ).

    mt_tree = lo_tree_model->get_tree( ).

  ENDMETHOD.


  METHOD _properties.

    DATA:
      lo_level    TYPE REF TO /mbtools/cl_tree_level,
      lv_tabname  TYPE tabname,
      lv_funcname TYPE funcname,
      lv_clsname  TYPE seoclsname.

    CREATE OBJECT lo_level
      EXPORTING
        io_tree  = mo_tree
        iv_level = iv_level.

    mo_tree->add_sub_node(
      iv_icon  = icon_icon_list
      iv_title = 'Properties'(007) ).

    lo_level->next( ).

    " BI Content
    SELECT SINGLE tlogo_d FROM rstlogoprop INTO lo_level->value
      WHERE tlogo = iv_tlogo.
    IF lo_level->value IS NOT INITIAL.
      /mbtools/cl_sap=>get_text_from_domain(
        EXPORTING
          iv_domain = 'RSTLOGO_D'
          iv_value  = lo_level->value
        IMPORTING
          ev_text   = lo_level->text ).

      mo_tree->add_detail(
        iv_icon  = iv_icon
        iv_title = 'BI Content Object'(013)
        iv_text  = lo_level->text
        iv_value = lo_level->value
        iv_level = lo_level->level ).
    ENDIF.

    " Description
    mo_tree->add_detail(
      iv_icon  = iv_icon
      iv_title = 'Respository Description'(014)
      iv_text  = iv_text
      iv_value = ''
      iv_level = lo_level->level ).

    " Icon
    SELECT SINGLE id name FROM icon INTO (lo_level->value, lo_level->text)
      WHERE id = iv_icon.
    IF sy-subrc = 0.
      mo_tree->add_detail(
        iv_icon  = iv_icon
        iv_title = 'Respository Icon'(015)
        iv_text  = lo_level->text
        iv_value = lo_level->value
        iv_level = lo_level->level
        iv_type  = /mbtools/if_objects=>c_icon ).
    ENDIF.

    " Object
    SELECT SINGLE ddtext FROM objt INTO lo_level->text
      WHERE objectname = iv_tlogo AND language = sy-langu ##WARN_OK.
    IF sy-subrc = 0.
      mo_tree->add_detail(
        iv_title = 'Object Description'(016)
        iv_text  = lo_level->text
        iv_level = lo_level->level ).
    ENDIF.

    SELECT SINGLE objecttype FROM objh INTO lo_level->value
      WHERE objectname = iv_tlogo ##WARN_OK.            "#EC CI_GENBUFF
    IF sy-subrc = 0.
      /mbtools/cl_sap=>get_text_from_domain(
        EXPORTING
          iv_domain = 'OB_TYP'
          iv_value  = lo_level->value
        IMPORTING
          ev_text   = lo_level->text ).

      mo_tree->add_detail(
        iv_title = 'Object Type'(017)
        iv_text  = lo_level->text
        iv_value = lo_level->value
        iv_level = lo_level->level ).
    ENDIF.

    " Package
    SELECT SINGLE b~devclass INTO lo_level->value
      FROM objs AS a JOIN tadir AS b
      ON a~tabname = b~obj_name
      WHERE a~objectname = iv_tlogo AND a~prim_table = 'X'
        AND b~pgmid = 'R3TR' AND b~object = 'TABL' ##WARN_OK. "#EC CI_BUFFJOIN
    IF sy-subrc = 0.
      SELECT SINGLE ctext FROM tdevct INTO lo_level->text
        WHERE devclass = lo_level->value AND spras = sy-langu.
      IF sy-subrc <> 0.
        lo_level->text = 'No text'(011).
      ENDIF.

      mo_tree->add_detail(
        iv_icon  = icon_package_standard
        iv_title = 'Package'(018)
        iv_text  = lo_level->text
        iv_value = lo_level->value
        iv_level = lo_level->level
        iv_type  = 'DEVC' ).
    ENDIF.

    " Primary table
    SELECT SINGLE tabname FROM objs INTO lv_tabname
      WHERE objectname = iv_tlogo AND prim_table = 'X' ##WARN_OK.
    IF sy-subrc = 0.
      _write_table(
        iv_table = lv_tabname
        iv_title = 'Primary Table'(030)
        iv_level = lo_level->level ).
    ENDIF.

    " Dependent tables
    SELECT tabname FROM objs INTO lv_tabname
      WHERE objectname = iv_tlogo AND prim_table = ''
      ORDER BY tabname.                                  "#EC CI_BYPASS

      _write_table(
        iv_table = lv_tabname
        iv_title = 'Dependent Table'(031)
        iv_level = lo_level->level ).

    ENDSELECT.

    " ABAP Class
    SELECT SINGLE class FROM rstlogoprop INTO lv_clsname
      WHERE tlogo = iv_tlogo.

    _write_class(
      iv_class = lv_clsname
      iv_title = 'ABAP Class'(032)
      iv_level = lo_level->level ).

    " ABAP Collection Class
    SELECT SINGLE class_coll FROM rstlogoprop INTO lv_clsname
      WHERE tlogo = iv_tlogo.

    _write_class(
      iv_class = lv_clsname
      iv_title = 'ABAP Class (Collection)'(033)
      iv_level = lo_level->level ).

    " Maintenance Function
    lv_funcname = 'RSO_' && iv_tlogo && '_MAINTAIN'.

    _write_function(
      iv_funct = lv_funcname
      iv_title = 'Maintenance Function'(034)
      iv_level = lo_level->level ).

    " Transport Functions
    lv_funcname = 'RS_' && iv_tlogo && '_BEFORE_EXPORT'.

    _write_function(
      iv_funct = lv_funcname
      iv_title = 'Before Export'(035)
      iv_level = lo_level->level ).

    lv_funcname = 'RS_' && iv_tlogo && '_AFTER_IMPORT'.

    _write_function(
      iv_funct = lv_funcname
      iv_title = 'After Import'(036)
      iv_level = lo_level->level ).

    lo_level->back( ).

  ENDMETHOD.


  METHOD _rspv.

    DATA lt_category TYPE TABLE OF rspccategory.

    FIELD-SYMBOLS <ls_category> TYPE rspccategory.

    SELECT * FROM rspccategory INTO TABLE lt_category
      ORDER BY category.
    ASSERT sy-subrc = 0.

    LOOP AT lt_category ASSIGNING <ls_category>.

      _rspv_category(
        is_category = <ls_category>
        iv_level    = iv_level ).

    ENDLOOP.

  ENDMETHOD.


  METHOD _rspv_category.

    DATA:
      lo_level   TYPE REF TO /mbtools/cl_tree_level,
      lt_variant TYPE TABLE OF rsprocesstypes.

    FIELD-SYMBOLS <ls_variant> TYPE rsprocesstypes.

    CREATE OBJECT lo_level
      EXPORTING
        io_tree  = mo_tree
        iv_level = iv_level.

    SELECT SINGLE description FROM rspccategoryt INTO lo_level->text
      WHERE category = is_category-category AND langu = sy-langu.
    IF sy-subrc <> 0.
      lo_level->text = 'No text'(011).
    ENDIF.

    lo_level->icon = is_category-icon.

    mo_tree->add_detail(
      iv_icon  = lo_level->icon
      iv_title = 'Process Category'(024)
      iv_text  = lo_level->text
      iv_value = is_category-category
      iv_level = lo_level->level ).

    lo_level->next( ).

    " Not a big table so reading all fields is ok
    SELECT * FROM rsprocesstypes INTO TABLE lt_variant
      WHERE category = is_category-category
      ORDER BY display_order.  "#EC CI_ALL_FIELDS_NEEDED "#EC CI_BYPASS
    IF sy-subrc = 0.

      " Use docu_obj field to hold description to keep it simple
      LOOP AT lt_variant ASSIGNING <ls_variant>.
        SELECT SINGLE description FROM rsprocesstypest INTO <ls_variant>-docu_obj
          WHERE type = <ls_variant>-type AND langu = sy-langu ##SUBRC_OK.
      ENDLOOP.

      CASE abap_true.
        WHEN mv_bytext.
          SORT lt_variant BY docu_obj.
        WHEN mv_byname.
          SORT lt_variant BY type.
          "WHEN mv_bysequ
          " Keep order
      ENDCASE.

      LOOP AT lt_variant ASSIGNING <ls_variant>.

        _rspv_type(
          is_variant = <ls_variant>
          iv_level   = lo_level->level ).

      ENDLOOP.

    ENDIF.

    lo_level->back( ).

  ENDMETHOD.


  METHOD _rspv_type.

    DATA:
      lo_level  TYPE REF TO /mbtools/cl_tree_level,
      lv_hidden TYPE abap_bool,
      lv_no_b4h TYPE abap_bool.

    CHECK is_variant-type NP 'Y*' AND is_variant-type NP 'Z*' OR is_variant-type NP '/*'.

    CREATE OBJECT lo_level
      EXPORTING
        io_tree  = mo_tree
        iv_level = iv_level.

    lo_level->text = is_variant-docu_obj.

    IF is_variant-type <> 'NDB_MERGE'.
      CALL FUNCTION 'RSSM_PROCESS_NEEDED'
        EXPORTING
          i_type         = is_variant-type
          i_simulate_b4h = abap_true
        IMPORTING
          e_hide         = lv_no_b4h.
    ENDIF.

    IF lv_no_b4h = abap_true.
      _check_b4h_mode(
        CHANGING
          co_level  = lo_level
          cv_hidden = lv_hidden ).
    ENDIF.

    mo_tree->add_detail(
      iv_icon   = is_variant-icon
      iv_title  = 'Process Type'(025)
      iv_text   = lo_level->text
      iv_value  = is_variant-type
      iv_level  = lo_level->level
      iv_hidden = lv_hidden ).

  ENDMETHOD.


  METHOD _write_class.

    DATA lo_level TYPE REF TO /mbtools/cl_tree_level.

    CHECK iv_class IS NOT INITIAL.

    CREATE OBJECT lo_level
      EXPORTING
        io_tree  = mo_tree
        iv_level = iv_level.

    SELECT SINGLE clsname FROM seoclass INTO lo_level->value
      WHERE clsname = iv_class.
    IF sy-subrc = 0.
      SELECT SINGLE descript FROM seoclasstx INTO lo_level->text
        WHERE clsname = iv_class AND langu = sy-langu.
      IF sy-subrc <> 0.
        lo_level->text = 'No text'(011).
      ENDIF.

      mo_tree->add_detail(
        iv_icon  = icon_abap
        iv_title = iv_title
        iv_text  = lo_level->text
        iv_value = lo_level->value
        iv_level = lo_level->level
        iv_type  = /mbtools/if_objects=>c_abap_class ).
    ENDIF.

  ENDMETHOD.


  METHOD _write_function.

    DATA lo_level TYPE REF TO /mbtools/cl_tree_level.

    CHECK iv_funct IS NOT INITIAL.

    CREATE OBJECT lo_level
      EXPORTING
        io_tree  = mo_tree
        iv_level = iv_level.

    SELECT SINGLE funcname FROM tfdir INTO lo_level->value
      WHERE funcname = iv_funct.
    IF sy-subrc = 0.
      SELECT SINGLE stext FROM tftit INTO lo_level->text
        WHERE funcname = iv_funct AND spras = sy-langu.
      IF sy-subrc <> 0.
        lo_level->text = 'No text'(011).
      ENDIF.

      mo_tree->add_detail(
        iv_icon  = icon_abap
        iv_title = iv_title
        iv_text  = lo_level->text
        iv_value = lo_level->value
        iv_level = lo_level->level
        iv_type  = /mbtools/if_objects=>c_abap_function ).
    ENDIF.

  ENDMETHOD.


  METHOD _write_table.

    DATA lo_level TYPE REF TO /mbtools/cl_tree_level.

    CHECK iv_table IS NOT INITIAL.

    CREATE OBJECT lo_level
      EXPORTING
        io_tree  = mo_tree
        iv_level = iv_level.

    SELECT SINGLE tabname FROM dd02l INTO lo_level->value
      WHERE tabname = iv_table ##WARN_OK.
    IF sy-subrc = 0.
      SELECT SINGLE ddtext FROM dd02t INTO lo_level->text
        WHERE tabname = iv_table AND as4local = 'A'
          AND ddlanguage = sy-langu ##WARN_OK.
      IF sy-subrc <> 0.
        lo_level->text = 'No text'(011).
      ENDIF.

      mo_tree->add_detail(
        iv_icon  = icon_database_table
        iv_title = iv_title
        iv_text  = lo_level->text
        iv_value = lo_level->value
        iv_level = lo_level->level
        iv_type  = /mbtools/if_objects=>c_table ).
    ENDIF.

  ENDMETHOD.
ENDCLASS.
