<!-- Title area -->
<div class="top_single_area">
    <?php 
        $crumb = '';
        if( function_exists( 'yoast_breadcrumb' ) ) {
            $crumb = yoast_breadcrumb('<div class="breadcrumb">','</div>', false);
        }
        if( ! is_string( $crumb ) || $crumb === '' ) {
            if(rehub_option('rehub_disable_breadcrumbs') == '1' || vp_metabox('rehub_post_side.disable_parts') == '1') {echo '';}
            elseif (function_exists('dimox_breadcrumbs')) {
                dimox_breadcrumbs(); 
            }
        }
        echo $crumb;  
    ?>
    <?php echo re_badge_create('label'); ?>
    <div class="top"><?php if (rehub_option('exclude_comments_meta') == 0) : ?><?php comments_popup_link( 0, 1, '%', 'comment_two', ''); ?><?php endif ;?></div>                            
    <h1 itemprop="name"><?php the_title(); ?></h1>                                
    <div class="meta post-meta">
        <?php if(rehub_option('exclude_author_meta') == 0) :?>
            <?php global $post; $author_id=$post->post_author; ?>
            <?php _e('By', 'rehub_framework') ;?> <a class="admin" href="<?php echo get_author_posts_url( $author_id )?>"><?php the_author_meta( 'nickname', $author_id ); ?></a>
        <?php endif; ?>
        <?php if(rehub_option('exclude_date_meta') == 0) :?>
            <?php _e('on', 'rehub_framework') ;?> <span class="date"><?php the_time(get_option( 'date_format' )); ?></span>
        <?php endif; ?>  
        <?php if(function_exists('get_favorites_button')) :?> <div class="favour_in_single favour_in_top"><?php the_favorites_button(); ?></div> <?php endif;?>
        <?php if(is_singular('post') && rehub_option('compare_btn_single') !='') :?>
            <?php $compare_cats = (rehub_option('compare_btn_cats') != '') ? ' cats="'.esc_html(rehub_option('compare_btn_cats')).'"' : '' ;?>
            <?php echo do_shortcode('[wpsm_compare_button'.$compare_cats.']'); ?> 
        <?php endif;?>
    </div>   
</div>