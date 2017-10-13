*&---------------------------------------------------------------------*
*& Include zabapgit_object_sxci
*&---------------------------------------------------------------------*

CLASS lcl_object_sxci DEFINITION INHERITING FROM lcl_objects_super FINAL.

  PUBLIC SECTION.
    INTERFACES lif_object.

  PRIVATE SECTION.
    CONSTANTS: BEGIN OF co_badi_component_name,
                 filters            TYPE string VALUE 'FILTERS',
                 function_codes     TYPE string VALUE 'FUNCTION_CODES',
                 control_composites TYPE string VALUE 'CONTROL_COMPOSITES',
                 customer_includes  TYPE string VALUE 'CUSTOMER_INCLUDES',
                 screens            TYPE string VALUE 'SCREENS',
               END OF co_badi_component_name.

ENDCLASS.

CLASS lcl_object_sxci IMPLEMENTATION.

  METHOD lif_object~has_changed_since.

    rv_changed = abap_true.

  ENDMETHOD.

  METHOD lif_object~changed_by.

    rv_user = c_user_unknown.

  ENDMETHOD.

  METHOD lif_object~get_metadata.

    rs_metadata = get_metadata( ).

  ENDMETHOD.

  METHOD lif_object~exists.

    DATA: lv_implementation_name TYPE rsexscrn-imp_name.

    lv_implementation_name = ms_item-obj_name.

    CALL FUNCTION 'SXV_IMP_EXISTS'
      EXPORTING
        imp_name           = lv_implementation_name
      EXCEPTIONS
        not_existing       = 1
        data_inconsistency = 2
        OTHERS             = 3.

    rv_bool = boolc( sy-subrc = 0 ).

  ENDMETHOD.

  METHOD lif_object~serialize.

    DATA: lv_implementation_name  TYPE rsexscrn-imp_name,
          lv_exit_name            TYPE rsexscrn-exit_name,
          lo_filter_object        TYPE REF TO cl_badi_flt_struct,
          ls_badi_definition      TYPE badi_data,
          ls_badi_implementation  TYPE impl_data,
          lo_filter_values_object TYPE REF TO cl_badi_flt_values_alv,
          lt_function_codes       TYPE seex_fcode_table,
          lt_control_composites   TYPE seex_coco_table,
          lt_customer_includes    TYPE seex_table_table,
          lt_screens              TYPE seex_screen_table,
          lt_filters              TYPE seex_filter_table,
          lt_methods              TYPE seex_mtd_table.

    lv_implementation_name = ms_item-obj_name.

    CALL FUNCTION 'SXV_EXIT_FOR_IMP'
      EXPORTING
        imp_name           = lv_implementation_name
      IMPORTING
        exit_name          = lv_exit_name
      TABLES
        filters            = lt_filters
      EXCEPTIONS
        data_inconsistency = 1
        OTHERS             = 2.

    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'error from SXV_EXIT_FOR_IMP' ).
    ENDIF.

    CALL FUNCTION 'SXO_BADI_READ'
      EXPORTING
        exit_name    = lv_exit_name
      IMPORTING
        badi         = ls_badi_definition
        filter_obj   = lo_filter_object
      TABLES
        fcodes       = lt_function_codes
        cocos        = lt_control_composites
        intas        = lt_customer_includes
        scrns        = lt_screens
        methods      = lt_methods
      EXCEPTIONS
        read_failure = 1
        OTHERS       = 2.

    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'error from SXV_EXIT_FOR_IMP' ).
    ENDIF.

    CALL FUNCTION 'SXO_IMPL_FOR_BADI_READ'
      EXPORTING
        imp_name          = lv_implementation_name
        exit_name         = lv_exit_name
        inter_name        = ls_badi_definition-inter_name
        filter_obj        = lo_filter_object
      IMPORTING
        impl              = ls_badi_implementation
        filter_values_obj = lo_filter_values_object
      TABLES
        fcodes            = lt_function_codes
        cocos             = lt_control_composites
        intas             = lt_customer_includes
        scrns             = lt_screens
      CHANGING
        methods           = lt_methods
      EXCEPTIONS
        read_failure      = 1
        OTHERS            = 2.

    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'error from SXV_EXIT_FOR_IMP' ).
    ENDIF.

    CLEAR: ls_badi_implementation-aname,
           ls_badi_implementation-adate,
           ls_badi_implementation-atime,
           ls_badi_implementation-uname,
           ls_badi_implementation-udate,
           ls_badi_implementation-utime,
           ls_badi_implementation-active.

    io_xml->add( iv_name = 'SXCI'
                 ig_data = ls_badi_implementation ).

    io_xml->add( iv_name = co_badi_component_name-filters
                 ig_data = lt_filters ).

    io_xml->add( iv_name = co_badi_component_name-function_codes
                 ig_data = lt_function_codes ).

    io_xml->add( iv_name = co_badi_component_name-control_composites
                 ig_data = lt_control_composites ).

    io_xml->add( iv_name = co_badi_component_name-customer_includes
                 ig_data = lt_customer_includes ).

    io_xml->add( iv_name = co_badi_component_name-screens
                 ig_data = lt_screens ).

  ENDMETHOD.

  METHOD lif_object~deserialize.

    DATA: ls_badi_implementation        TYPE impl_data,
          lt_filters                    TYPE seex_filter_table,
          lt_function_codes             TYPE seex_fcode_table,
          lt_control_composites         TYPE seex_coco_table,
          lt_customer_includes          TYPE seex_table_table,
          lt_screens                    TYPE seex_screen_table,
          ls_badi_definition            TYPE badi_data,
          lo_filter_object              TYPE REF TO cl_badi_flt_struct,
          lo_filter_val_obj             TYPE REF TO cl_badi_flt_values_alv,
          lv_korrnum                    TYPE trkorr,
          lv_filter_type_enhanceability TYPE rsexscrn-flt_ext,
          lv_package                    TYPE devclass.

    io_xml->read(
      EXPORTING
        iv_name = 'SXCI'
      CHANGING
        cg_data = ls_badi_implementation ).

    io_xml->read(
      EXPORTING
        iv_name = co_badi_component_name-filters
      CHANGING
        cg_data = lt_filters ).

    io_xml->read(
      EXPORTING
        iv_name = co_badi_component_name-function_codes
      CHANGING
        cg_data = lt_function_codes ).

    io_xml->read(
      EXPORTING
        iv_name = co_badi_component_name-control_composites
      CHANGING
        cg_data = lt_control_composites ).

    io_xml->read(
      EXPORTING
        iv_name = co_badi_component_name-customer_includes
      CHANGING
        cg_data = lt_customer_includes ).

    io_xml->read(
      EXPORTING
        iv_name = co_badi_component_name-screens
      CHANGING
        cg_data = lt_screens ).

    CALL FUNCTION 'SXO_BADI_READ'
      EXPORTING
        exit_name    = ls_badi_implementation-exit_name
      IMPORTING
        badi         = ls_badi_definition
        filter_obj   = lo_filter_object
      EXCEPTIONS
        read_failure = 1
        OTHERS       = 2.

    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'error from SXO_BADI_READ' ).
    ENDIF.

    lv_package = iv_package.

    CREATE OBJECT lo_filter_val_obj
      EXPORTING
        filter_object = lo_filter_object
        filter_values = lt_filters.

    CALL FUNCTION 'SXO_IMPL_SAVE'
      EXPORTING
        impl             = ls_badi_implementation
        flt_ext          = lv_filter_type_enhanceability
        filter_val_obj   = lo_filter_val_obj
        genflag          = abap_true
        no_dialog        = abap_true
      TABLES
        fcodes_to_insert = lt_function_codes
        cocos_to_insert  = lt_control_composites
        intas_to_insert  = lt_customer_includes
        sscrs_to_insert  = lt_screens
      CHANGING
        korrnum          = lv_korrnum
        devclass         = lv_package
      EXCEPTIONS
        save_failure     = 1
        action_canceled  = 2
        OTHERS           = 3.

    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'error from SXO_IMPL_SAVE' ).
    ENDIF.

    CALL FUNCTION 'SXO_IMPL_ACTIVE'
      EXPORTING
        imp_name                  = ls_badi_implementation-imp_name
        no_dialog                 = abap_true
      EXCEPTIONS
        badi_not_existing         = 1
        imp_not_existing          = 2
        already_active            = 3
        data_inconsistency        = 4
        activation_not_admissable = 5
        action_canceled           = 6
        access_failure            = 7
        OTHERS                    = 8.

    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'error from SXO_IMPL_ACTIVE' ).
    ENDIF.

  ENDMETHOD.

  METHOD lif_object~delete.

    DATA: lv_implementation_name TYPE rsexscrn-imp_name.

    lv_implementation_name = ms_item-obj_name.

    CALL FUNCTION 'SXO_IMPL_DELETE'
      EXPORTING
        imp_name           = lv_implementation_name
        no_dialog          = abap_true
      EXCEPTIONS
        imp_not_existing   = 1
        action_canceled    = 2
        access_failure     = 3
        data_inconsistency = 4
        OTHERS             = 5.

    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'error from SXO_IMPL_DELETE' ).
    ENDIF.

  ENDMETHOD.


  METHOD lif_object~jump.

    CALL FUNCTION 'RS_TOOL_ACCESS'
      EXPORTING
        operation           = 'SHOW'
        object_name         = ms_item-obj_name
        object_type         = ms_item-obj_type
        in_new_window       = abap_true
      EXCEPTIONS
        not_executed        = 1
        invalid_object_type = 2
        OTHERS              = 3.

    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'error from RS_TOOL_ACCESS' ).
    ENDIF.

  ENDMETHOD.

  METHOD lif_object~compare_to_remote_version.

    CREATE OBJECT ro_comparison_result TYPE lcl_comparison_null.

  ENDMETHOD.

ENDCLASS.
