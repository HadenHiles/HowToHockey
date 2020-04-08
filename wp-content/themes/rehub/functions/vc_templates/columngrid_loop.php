<?php 
    $post_formats = $enable_pagination = $data_source = $cat = $ids = $orderby = $order = $meta_key = $show = $offset = $columns = $enable_btn = $exerpt_count = $cat_exclude = $tag_exclude = $tag = $post_type = $tax_name = $tax_slug = $tax_slug_exclude ='';   
    $atts = vc_map_get_attributes( $this->getShortcode(), $atts );
    extract( $atts ); 
    if ($order =='') {$order = 'DESC';}
    if ($columns =='') {$columns = '3_col';}
    if ($exerpt_count =='') {$exerpt_count = '120';}   
    $infinitescrollwrap = ($enable_pagination =='2') ? ' inf_scr_wrap_auto' : '';   
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
        if ($enable_pagination != '' && $enable_pagination != '0') {$args['paged'] = $paged;}
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
        if ($enable_pagination != '' && $enable_pagination != '0') {$args['paged'] = $paged;}
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
    if(class_exists('MetaDataFilter') AND MetaDataFilter::is_page_mdf_data()){   
        $_REQUEST['mdf_do_not_render_shortcode_tpl'] = true;
        $_REQUEST['mdf_get_query_args_only'] = true;
        do_shortcode('[meta_data_filter_results]');
        $args = $_REQUEST['meta_data_filter_args'];
        $wp_query=new WP_Query($args);
        $_REQUEST['meta_data_filter_found_posts']=$wp_query->found_posts;
    }
    else { $wp_query = new WP_Query($args); }
?>
<div class="<?php echo $infinitescrollwrap ;?>">
<?php $i=1; if ( $wp_query->have_posts() ) : ?>                      
<?php while ( $wp_query->have_posts() ) : $wp_query->the_post();?>
  
    <?php if ($columns == '3_col') :?>
    <article class="inf_scr_item column_grid<?php if (($i % 3) == '0') :?> last-col<?php endif ?><?php if (($i % 3) == '1') :?> first-col<?php endif ?>">
    <?php elseif ($columns == '4_col') :?>
    <article class="inf_scr_item col_4_grid column_grid<?php if (($i % 4) == '0') :?> last-col<?php endif ?><?php if (($i % 4) == '1') :?> first-col<?php endif ?>">
    <?php endif ;?> 
        <figure><?php echo re_badge_create('ribbonleft'); ?> 
            <?php if(function_exists('get_favorites_button')) :?> <div class="favour_in_image"><?php the_favorites_button(); ?></div> <?php endif;?>            
            <a href="<?php the_permalink();?>"><?php wpsm_thumb ('news_big') ?></a>
        </figure>
        <div class="content_constructor">
            <h2><a href="<?php the_permalink();?>"><?php the_title();?></a></h2>
            <div class="rehub_catalog_desc">                                 
                <?php kama_excerpt('maxchar='.$exerpt_count.''); ?>                       
            </div> 
            <?php if($enable_btn):?>
                <?php rehub_create_btn('yes');?>
            <?php endif?>
        </div>                           
    </article>
<?php $i++; endwhile; endif; ?>
</div>
<div class="clearfix"></div>
<?php if ($enable_pagination == '1') :?>
    <div class="pagination"><?php rehub_pagination();?></div>
<?php elseif ($enable_pagination == '2') :?> 
    <?php wp_enqueue_script('infinitescroll'); ?>
    <div class="more_post"><?php echo get_next_posts_link('' . __('More posts', 'rehub_framework') . ''); ?></div>      
<?php endif ;?>
<?php  wp_reset_query(); ?>