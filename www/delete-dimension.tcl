# packages/ratings/www/delete-dimensions
ad_page_contract {
    Deletes a dimension

    @author Miguel Marin (miguelmarin@viaro.net)
    @author Viaro Networks www.viaro.net
} {
    dimension_id:multiple,notnull
}


foreach dimension $dimension_id {
    db_exec_plsql delete_dimension {  }
}

ad_returnredirect "add-dimension"