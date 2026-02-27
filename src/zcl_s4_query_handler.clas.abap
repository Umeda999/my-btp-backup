CLASS zcl_s4_query_handler DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider .

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_s4_query_handler IMPLEMENTATION.

  METHOD if_rap_query_provider~select.
    " この時点で io_request と io_response が使えるようになります

    DATA:
      lt_business_data TYPE TABLE OF z_scm_s4data=>tys_ztrial_test_cdstype,
      lo_http_client   TYPE REF TO if_web_http_client,
      lo_client_proxy  TYPE REF TO /iwbep/if_cp_client_proxy,
      lo_request       TYPE REF TO /iwbep/if_cp_request_read_list,
      lo_response      TYPE REF TO /iwbep/if_cp_response_read_lst.

    TRY.
        " 1. Destinationの取得
        DATA(lo_destination) = cl_http_destination_provider=>create_by_cloud_destination(
                                 i_name = 'S4HANA_trial' ).

        " 2. HTTPクライアントの作成
        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( lo_destination ).

        " 3. ODataプロキシの作成
        lo_client_proxy = /iwbep/cl_cp_factory_remote=>create_v2_remote_proxy(
          EXPORTING
             is_proxy_model_key       = VALUE #( repository_id       = 'DEFAULT'
                                                 proxy_model_id      = 'Z_SCM_S4DATA'
                                                 proxy_model_version = '0001' )
            io_http_client             = lo_http_client
            iv_relative_service_root   = '/sap/opu/odata/sap/ZUI_TRIAL_V2/' ).

        " 4. リクエストの作成
        lo_request = lo_client_proxy->create_resource_for_entity_set( 'ZTRIAL_TEST_CDS' )->create_request_for_read( ).
        lo_request->set_top( 50 )->set_skip( 0 ).

        " 5. 実行とデータ受取
        lo_response = lo_request->execute( ).
        lo_response->get_business_data( IMPORTING et_business_data = lt_business_data ).

        " 6. 出力データの設定 (io_responseを使用)
        io_response->set_data( lt_business_data ).

        " 7. 件数の設定 (io_requestを使用)
IF io_request->is_total_numb_of_rec_requested( ).
  io_response->set_total_number_of_records( lines( lt_business_data ) ).
ENDIF.

      CATCH cx_root INTO DATA(lx_error).
        " デバッグ用：ここにブレークポイントを置くとエラー内容がわかります
        RAISE SHORTDUMP lx_error.
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
