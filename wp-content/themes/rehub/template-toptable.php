<?php
    /* Template Name: Top table constructor (NEW) */
?>
<?php 
    $module_cats = vp_metabox('rehub_top_table.top_review_cat');
    $module_tag = vp_metabox('rehub_top_table.top_review_tag');
    $module_fetch = intval(vp_metabox('rehub_top_table.top_review_fetch'));
    $module_width = vp_metabox('rehub_top_table.top_review_width');
    $module_ids = vp_metabox('rehub_top_table.manual_ids');
    $module_custom_post = vp_metabox('rehub_top_table.top_review_custompost');
    $catalog_tax = vp_metabox('rehub_top_table.catalog_tax');
    $catalog_tax_slug = vp_metabox('rehub_top_table.catalog_tax_slug');    
    $order_choose = vp_metabox('rehub_top_table.top_review_choose');
    $rating_circle = vp_metabox('rehub_top_table.top_review_circle');
    $module_pagination = vp_metabox('rehub_top_table.top_review_pagination');
    $module_field_sorting = vp_metabox('rehub_top_table.top_review_field_sort');
    $module_order = vp_metabox('rehub_top_table.top_review_order');
    $first_column_enable = vp_metabox('rehub_top_table.first_column_enable');
    $first_column_rank = vp_metabox('rehub_top_table.first_column_rank');
    $last_column_enable = vp_metabox('rehub_top_table.last_column_enable');
    $first_column_name = (vp_metabox('rehub_top_table.first_column_name') !='') ? esc_html(vp_metabox('rehub_top_table.first_column_name')) : __('Product', 'rehub_framework') ;
    $last_column_name = (vp_metabox('rehub_top_table.last_column_name') !='') ? esc_html(vp_metabox('rehub_top_table.last_column_name')) : '' ;
    $affiliate_link = vp_metabox('rehub_top_table.first_column_link');
    $rows = vp_metabox('rehub_top_table.columncontents');  //Get the rows  
    if ($module_fetch ==''){$module_fetch = '10';};   
    if ($rating_circle ==''){$rating_circle = '1';};
    $module_after = vp_metabox('rehub_top_table.column_after_block');

?>
<?php get_header(); ?>
    <!-- CONTENT -->
    <div class="content"> 
	    <?php if(rehub_option('rehub_featured_toggle') && is_front_page() && !is_paged()) : ?>
	        <?php get_template_part('inc/parts/featured'); ?>
	    <?php endif; ?>
	    <?php if(rehub_option('rehub_homecarousel_toggle') && is_front_page() && !is_paged()) : ?>
	        <?php get_template_part('inc/parts/home_carousel'); ?>
	    <?php endif; ?>    
		<div class="clearfix">
		    <!-- Main Side -->
            <div class="main-side page clearfix<?php if ($module_width =='1') : ?> full_width<?php endif;?>">
                <div class="title"><h1><?php the_title(); ?></h1></div>
                <?php if (!is_paged()) :?>
                    <article class="top_rating_text post">
                        <?php if (have_posts()) : while (have_posts()) : the_post(); ?><?php the_content(); ?><?php endwhile; endif; ?>
                    </article>
                    <div class="clearfix"></div>
                <?php endif; ?>
                <?php $paged = ( get_query_var('paged') ) ? get_query_var('paged') : 1; ?>
                <?php if ($order_choose == 'cat_choose') :?>
	                <?php $query = array( 
	                    'cat' => $module_cats, 
	                    'tag' => $module_tag, 
                        'posts_per_page' => $module_fetch, 
                        'paged' => $paged, 
	                    'post_status' => 'publish', 
	                    'ignore_sticky_posts' => 1, 
	                );
	                ?> 
                    <?php if(!empty ($module_field_sorting)) {$query['meta_key'] = $module_field_sorting; $query['orderby'] = 'meta_value_num';} ?>
                    <?php if($module_order =='asc') {$query['order'] = 'ASC';} ?>
            	<?php elseif ($order_choose == 'manual_choose' && $module_ids !='') :?>
	                <?php $query = array( 
	                    'post_status' => 'publish', 
	                    'ignore_sticky_posts' => 1, 
	                    'orderby' => 'post__in',
	                    'post__in' => $module_ids,
                        'posts_per_page'=> -1,

	                );
	                ?>
                <?php elseif ($order_choose == 'custom_post') :?>
                    <?php $query = array(  
                        'posts_per_page' => $module_fetch, 
                        'paged' => $paged, 
                        'post_status' => 'publish', 
                        'ignore_sticky_posts' => 1,
                        'post_type' => $module_custom_post, 
                    );
                    ?> 
                    <?php if (!empty ($catalog_tax_slug) && !empty ($catalog_tax)) : ?>
                        <?php $query['tax_query'] = array (
                            array(
                                'taxonomy' => $catalog_tax,
                                'field'    => 'slug',
                                'terms'    => $catalog_tax_slug,
                            ),
                        );?>
                    <?php endif ?>
                    <?php if(!empty ($module_field_sorting)) {$query['meta_key'] = $module_field_sorting; $query['orderby'] = 'meta_value_num';} ?>
                    <?php if($module_order =='asc') {$query['order'] = 'ASC';} ?>                                                            
            	<?php else :?>
	                <?php $query = array( 
                        'posts_per_page' => 10, 
	                    'paged' => $paged, 
	                    'post_status' => 'publish', 
	                    'ignore_sticky_posts' => 1, 
	                );
	                ?> 
                    <?php if(!empty ($module_field_sorting)) {$query['meta_key'] = $module_field_sorting; $query['orderby'] = 'meta_value_num';} ?>
                    <?php if($module_order =='asc') {$query['order'] = 'ASC';} ?>                                		
            	<?php endif ;?>	

                <?php 
                if(class_exists('MetaDataFilter') AND MetaDataFilter::is_page_mdf_data()){
     
                    $_REQUEST['mdf_do_not_render_shortcode_tpl'] = true;
                    $_REQUEST['mdf_get_query_args_only'] = true;
                    do_shortcode('[meta_data_filter_results]');
                    $args = $_REQUEST['meta_data_filter_args'];
                    global $wp_query;
                    $wp_query=new WP_Query($args);
                    $_REQUEST['meta_data_filter_found_posts']=$wp_query->found_posts;
                }
                else { $wp_query = new WP_Query($query); }    
                $i=0; if ($wp_query->have_posts()) :?>
                <?php wp_enqueue_script('tablesorter'); wp_enqueue_style('tabletoggle'); ?>
                <table  data-tablesaw-sortable data-tablesaw-sortable-switch class="tablesaw top_table_block<?php if ($module_width =='1') : ?> full_width_rating<?php else :?> with_sidebar_rating<?php endif;?> tablesorter" cellspacing="0">
                    <thead> 
                    <tr class="top_rating_heading">
                        <?php if ($first_column_enable):?><th class="product_col_name" data-tablesaw-sortable-col data-tablesaw-priority="persist"><?php echo $first_column_name; ?></th><?php endif;?>
                        <?php if (!empty ($rows)) {
                            $nameid=0;                       
                            foreach ($rows as $row) {                       
                            $col_name = vp_metabox('rehub_top_table.columncontents.'.$nameid.'.column_name');
                            echo '<th class="col_name" data-tablesaw-sortable-col data-tablesaw-priority="1">'.esc_html($col_name).'</th>';
                            $nameid++;
                            } 
                        }
                        ?>
                        <?php if ($last_column_enable):?><th class="buttons_col_name" data-tablesaw-sortable-col data-tablesaw-priority="1"><?php echo $last_column_name; ?></th><?php endif;?>                      
                    </tr>
                    </thead>
                    <tbody>
                <?php while ($wp_query->have_posts()) : $wp_query->the_post(); $i ++?>     
                    <tr class="top_rating_item" id='rank_<?php echo $i?>'>
                        <?php if ($first_column_enable):?>
                            <td class="product_image_col"><?php echo re_badge_create('tablelabel'); ?>
                                <figure>   
                                                                   
                                    <?php $link_on_thumb = ($affiliate_link =='1') ? rehub_create_affiliate_link() : get_the_permalink(); ?>
                                    <?php $link_on_thumb_target = ($affiliate_link =='1') ? ' class="btn_offer_block" target="_blank" rel="nofollow"' : '' ; ?>
                                    <a href="<?php echo $link_on_thumb;?>"<?php echo $link_on_thumb_target;?>>
                                    <?php $img = get_post_thumb(); $nothumb = get_template_directory_uri() . '/images/default/noimage_200_140.png' ;
                                    if( rehub_option( 'aq_resize_crop') == '1') {$params = array( 'width' => 120);}
                                    else {$params = array( 'width' => 120, 'height' => 120, 'crop' => true);} ?>
                                    <?php if(!empty($img)) : ?>
                                        <img src="<?php echo bfi_thumb( $img, $params ); ?>" alt="<?php the_title_attribute(); ?>" />
                                    <?php else : ?>    
                                        <img src="<?php echo $nothumb; ?>" alt="<?php the_title_attribute(); ?>" />
                                    <?php endif ; ?>                                    
                                    </a>
                                </figure>
                            </td>
                        <?php endif;?>
                        <?php 
                        if (!empty ($rows)) {
                            $pbid=0;                       
                            foreach ($rows as $row) {
                            $centered = ($row['column_center']== '1') ? ' centered_content' : '' ;
                            echo '<td class="column_'.$pbid.' column_content'.$centered.'">';
                            echo do_shortcode(wp_kses_post($row['column_html']));                       
                            $element = $row['column_type'];
                                if ($element == 'meta_value') {
                                    include(locate_template('inc/top/metacolumn.php'));
                                } else if ($element == 'review_function') {
                                    include(locate_template('inc/top/reviewcolumn.php'));
                                } else if ($element == 'user_review_function') {
                                    include(locate_template('inc/top/userreviewcolumn.php'));                                            
                                } else {
                                    
                                };
                            echo '</td>';
                            $pbid++;
                            } 
                        }
                        ?>
                        <?php if ($last_column_enable):?>
                            <td class="buttons_col">
                                
                            	<?php rehub_create_btn('') ;?>                                
                            </td>
                        <?php endif ;?>
                    </tr>
                <?php endwhile; ?>
                    </tbody>
                </table>
                <?php else: ?><?php _e('No posts for this criteria.', 'rehub_framework'); ?>
                <?php endif; ?>
                <?php if ($module_pagination =='1') :?><div class="pagination"><?php rehub_pagination();?></div><?php endif ;?>
                <?php wp_reset_query(); ?>
                <?php if ($module_after !=''):?>
                    <div class="clearfix"></div>
                    <article class="post after_top_module"><?php echo do_shortcode(wp_kses_post($module_after));  ?></article>
                <?php endif ;?>                
			</div>	
            <!-- /Main Side -->  
            <?php if ($module_width !='1') : ?>
            <!-- Sidebar -->
            <?php get_sidebar(); ?>
            <!-- /Sidebar --> 
            <?php endif;?>
        </div>
    </div>
    <!-- /CONTENT -->     
<!-- FOOTER -->
<?php get_footer(); ?>