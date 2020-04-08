<?php 
    $title_name=$title_position=$title_url='';
    $atts = vc_map_get_attributes( $this->getShortcode(), $atts );
    extract( $atts );
    $title_enable = 1; 
    $title_url = ( $title_url == '||' ) ? '' : $title_url;
    $title_url = vc_build_link( $title_url );
    $title_url_title = ($title_url !='') ? $title_url['title'] : '';
    $title_url_url = ($title_url !='') ? $title_url['url'] : ''; 

?>
<?php if( !is_paged()) : ?>
<?php title_custom_block ($title_enable, $title_name, $title_position, $title_url_title, $title_url_url) ?>
<?php endif ; ?>