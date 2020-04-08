<?php 
	$post_formats = $enable_pagination = $data_source = $cat = $ids = $orderby = $order = $meta_key = $show = $offset = $cat_exclude = $tag_exclude = $tag = $post_type = $tax_name = $tax_slug = $tax_slug_exclude ='';
    $order = 'DESC';
    $atts = vc_map_get_attributes( $this->getShortcode(), $atts );
    extract( $atts );  		    
?>
<?php
	global $wp_query; 
	if ( get_query_var('paged') ) { $paged = get_query_var('paged'); } else if ( get_query_var('page') ) {$paged = get_query_var('page'); } else {$paged = 1; }
    if ($data_source == 'ids' && $ids !='') {
        $ids = explode(',', $ids);
        $args = array(
            'post__in' => $ids,
            'numberposts' => '-1',
            'orderby' => 'post__in',            
        );
    }
    elseif ($data_source == 'cat') {
        $args = array(
            'post_type' => 'post',
            'posts_per_page'   => $show, 
            'orderby' => $orderby,
            'order' => $order,
            'ignore_sticky_posts' => 1,                  
        );
        if ($enable_pagination != '') {$args['paged'] = $paged;}
        if ($offset != '') {$args['offset'] = $offset;}
        if (($orderby == 'meta_value' || $orderby == 'meta_value_num') && $meta_key !='') {$args['meta_key'] = $meta_key;}
        if ($cat !='') {$args['cat'] = $cat;}
        if ($tag !='') {$args['tag__in'] = explode(',', $tag);}
        if ($cat_exclude !='') {$args['category__not_in'] = explode(',', $cat_exclude);}
        if ($tag_exclude !='') {$args['tag__not_in'] = explode(',', $tag_exclude);}
        if ($post_formats != 'all') {$args['meta_key'] = 'rehub_framework_post_type'; $args['meta_value'] = $post_formats;}
    }   
    elseif ($data_source == 'cpt') {
        $args = array(
            'post_type' => $post_type,
            'posts_per_page'   => $show, 
            'orderby' => $orderby,
            'order' => $order,
            'ignore_sticky_posts' => 1,                  
        );
        if ($enable_pagination != '') {$args['paged'] = $paged;}
        if ($offset != '') {$args['offset'] = $offset;}
        if (($orderby == 'meta_value' || $orderby == 'meta_value_num') && $meta_key !='') {$args['meta_key'] = $meta_key;}
        if ($post_formats != 'all') {$args['meta_key'] = 'rehub_framework_post_type'; $args['meta_value'] = $post_formats;}
        if (!empty ($tax_name) && !empty ($tax_slug)) {
            $args['tax_query'] = array (
                array(
                    'taxonomy' => $tax_name,
                    'field'    => 'slug',
                    'terms'    => array($tax_slug),
                )
            );
        }
        if (!empty ($tax_name) && !empty ($tax_slug_exclude)) {
            $args['tax_query'] = array (
                array(
                    'taxonomy' => $tax_name,
                    'field'    => 'slug',
                    'terms'    => array($tax_slug_exclude),
                    'operator' => 'NOT IN',
                ),
            );
        }        
    }    
	$wp_query = new WP_Query($args);
?> 
<?php if($wp_query->have_posts()): while($wp_query->have_posts()): $wp_query->the_post(); ?>
	<?php include(locate_template('inc/parts/query_type2.php')); ?>
<?php endwhile; endif; ?>
<div class="clearfix"></div>
<?php if ($enable_pagination != '') :?>
	<?php rehub_pagination();?>
<?php endif ;?>
<?php  wp_reset_query(); ?>