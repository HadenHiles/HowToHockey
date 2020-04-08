<article class="small_post<?php if(is_sticky()) {echo " sticky";} ?>">
    <div class="top">
        <div class="cats_def">
            <?php
            if(rehub_option('exclude_cat_meta') != 1) {
                $category = get_the_category();
                if($category){
                    $first_cat = $category[0]->term_id;
                    $cat_data = get_option("category_$first_cat");
                    $output='';
                    $output .= '<a href="'.get_category_link($first_cat ).'" class="cat-'.$first_cat.'"';
                    if (!empty($cat_data['cat_color'])) {
                      $output .= ' style="color: '.$cat_data["cat_color"].' !important; "';
                    } 
                    $output .='>'.$category[0]->cat_name.'</a>';               
                    echo $output;
                }
            }
            ?>
         </div>
        <?php if (rehub_option('exclude_comments_meta') == 0) : ?><?php comments_popup_link( 0, 1, '%', 'comment_two', ''); ?><?php endif ;?>
    </div>
    <h2><?php if(is_sticky()) {echo "<i class='fa fa-thumb-tack'></i>";} ?><a href="<?php the_permalink();?>"><?php the_title();?></a></h2>
    <div class="post-meta"> <?php meta_all( true, false, true ); ?> </div>
    <?php rehub_format_score('small') ?>
    <?php if(vp_metabox('rehub_post.rehub_framework_post_type') == 'gallery') : ?>
    	<?php $gallery_images = vp_metabox('rehub_post.gallery_post.0.gallery_post_images'); ?>
        <?php $gallery_i=0; foreach ($gallery_images as $gallery_img) { $gallery_i++;} ;?>
		<?php if (  (function_exists('has_post_thumbnail')) && (has_post_thumbnail())  ) { ?>
            <figure class="slider_post">                   
                <div class="pattern"></div>
                <div class="caption"><a href="<?php the_permalink();?>">+<?php echo $gallery_i; ?></a><i class="fa fa-camera"></i></div>
                <?php rehub_formats_icons(); ?>
                <?php if( rehub_option( 'aq_resize') == 1 ) : ?>
                    <?php $img = get_post_thumb(); ?> 
                    <a href="<?php the_permalink();?>"><img src="<?php $params = array( 'width' => 300, 'height' => 200, 'crop' => true  ); echo bfi_thumb($img, $params); ?>" alt="<?php the_title(); ?>" /></a>
                <?php else :?>    
                    <a href="<?php the_permalink();?>"><?php the_post_thumbnail('grid_news'); ?></a>
                <?php endif ;?>
            </figure>                                     
		<?php } ?> 
    <?php elseif(vp_metabox('rehub_post.rehub_framework_post_type') == 'music') : ?>
        <?php if(vp_metabox('rehub_post.music_post.0.music_post_source') == 'music_post_soundcloud') : ?>
            <div class="music_soundcloud">
                <?php echo vp_metabox('rehub_post.music_post.0.music_post_soundcloud_embed'); ?>
            </div>       
        <?php elseif(vp_metabox('rehub_post.music_post.0.music_post_source') == 'music_post_spotify') : ?>
            <div class="music_spotify">
                <iframe src="https://embed.spotify.com/?uri=<?php echo vp_metabox('rehub_post.music_post.0.music_post_spotify_embed'); ?>" width="100%" height="80" frameborder="0" allowtransparency="true"></iframe>
            </div>
        <?php endif; ?>   
    <?php else : ?>   
        <figure>
            <?php if(rehub_option('repick_social_disable') !='1') :?> <?php echo rehub_social_inimage('minimal'); ?> <?php endif;?>
            <?php echo re_badge_create('ribbonleft'); ?>
            <div class="pattern"></div>
            <?php rehub_formats_icons('full'); ?>
            <a href="<?php the_permalink();?>"><?php wpsm_thumb ('grid_news') ?></a>
        </figure>                                       
    <?php endif; ?>
    <p><?php kama_excerpt('maxchar=320'); ?></p>
	<?php if(rehub_option('disable_btn_offer_loop')!='1')  : ?><?php rehub_create_btn('yes') ;?><?php endif; ?>   
</article>