<?php get_header(); ?>
    <!-- CONTENT -->
    <div class="content"<?php if(is_singular( 'post' ) && rehub_option('disable_product_schema') !='1') : ?> itemscope="" itemtype="http://schema.org/Product"<?php endif; ?>> 
		<div class="clearfix">
        <?php if(rehub_option('rehub_disable_fulltitle') !='1')  : ?>
            <?php get_template_part('inc/parts/top_title'); ?>
        <?php endif; ?>

		    <!-- Main Side -->
            <div class="main-side single<?php if(vp_metabox('rehub_post_side.post_size') == 'full_post') : ?> full_width<?php endif; ?> clearfix">            
            <?php if (have_posts()) : while (have_posts()) : the_post(); ?>
                <article class="post post-inner <?php $category = get_the_category($post->ID); if ($category) {$first_cat = $category[0]->term_id; echo 'category-'.$first_cat.'';} ?>" id="post-<?php the_ID(); ?>">
                    <?php if(rehub_option('rehub_disable_fulltitle') =='1')  : ?>
                        <?php get_template_part('inc/parts/top_title'); ?>
                    <?php endif; ?>
                    <?php if(rehub_option('rehub_single_after_title') && vp_metabox('rehub_post_side.show_banner_ads') != '1') : ?><div class="mediad mediad_top"><?php echo do_shortcode(rehub_option('rehub_single_after_title')); ?></div><div class="clearfix"></div><?php endif; ?>
                    <?php if(rehub_option('rehub_disable_share_top') =='1' || vp_metabox('rehub_post_side.disable_parts') == '1')  : ?>
                    <?php else :?>
                        <div class="top_share"><?php get_template_part('inc/parts/post_share'); ?></div>
                        <div class="clearfix"></div> 
                    <?php endif; ?>                	
                    <?php if(vp_metabox('rehub_post.rehub_framework_post_type') == 'review' && vp_metabox('rehub_post.review_post.0.review_post_schema_type') == 'review_woo_product' && vp_metabox('rehub_post.review_post.0.review_woo_product.0.review_woo_slider') =='1') :?>
                        <?php get_template_part('inc/parts/woo_slider'); ?>
                	<?php elseif(vp_metabox('rehub_post.rehub_framework_post_type') == 'review' && vp_metabox('rehub_post.review_post.0.rehub_review_slider') =='1') :?>                     
                        <?php get_template_part('inc/parts/review_slider'); ?>
                    <?php else :?> 
                    	<?php get_template_part('inc/parts/top_image'); ?>
                    <?php endif; ?>

                    <?php if(vp_metabox('rehub_post.rehub_framework_post_type') == 'music') : ?>
                        <?php if(vp_metabox('rehub_post.music_post.0.music_post_source') == 'music_post_soundcloud') : ?>
                            <div class="music_soundcloud">
                                <?php echo vp_metabox('rehub_post.music_post.0.music_post_soundcloud_embed'); ?>
                            </div>                        
                        <?php elseif(vp_metabox('rehub_post.music_post.0.music_post_source') == 'music_post_spotify') : ?>
                            <div class="music_spotify">
                                <iframe src="https://embed.spotify.com/?uri=<?php echo vp_metabox('rehub_post.music_post.0.music_post_spotify_embed'); ?>" width="100%" height="80" frameborder="0" allowtransparency="true"></iframe>
                            </div>
                        <?php endif; ?>
                    <?php endif; ?>

                    <?php if(rehub_option('rehub_single_before_post') && vp_metabox('rehub_post_side.show_banner_ads') != '1') : ?><div class="mediad mediad_before_content"><?php echo do_shortcode(rehub_option('rehub_single_before_post')); ?></div><?php endif; ?>

                    <?php the_content(); ?>                                           
                
                </article>

                <div class="clearfix"></div>
                <?php echo re_badge_create('labelbig'); ?>
                <?php if(rehub_option('rehub_single_code') && vp_metabox('rehub_post_side.show_banner_ads') != '1') : ?><div class="single_custom_bottom"><?php echo do_shortcode (rehub_option('rehub_single_code')); ?></div><div class="clearfix"></div><?php endif; ?>
               
                <?php if(rehub_option('rehub_disable_share') =='1' || vp_metabox('rehub_post_side.disable_parts') == '1')  : ?>
                <?php else :?>
                    <?php get_template_part('inc/parts/post_share'); ?>  
                <?php endif; ?>

                <?php if(rehub_option('rehub_disable_prev') =='1' || vp_metabox('rehub_post_side.disable_parts') == '1')  : ?>
                <?php else :?>
                    <?php get_template_part('inc/parts/prevnext'); ?>                    
                <?php endif; ?>                 

                <?php if(rehub_option('rehub_disable_tags') =='1' || vp_metabox('rehub_post_side.disable_parts') == '1')  : ?>
                <?php else :?>
                    <div class="tags">
                        <p><?php the_tags(__('Tags: ', 'rehub_framework'),", "); ?></p>
                    </div>
                <?php endif; ?>

                <?php if(rehub_option('rehub_disable_author') =='1' || vp_metabox('rehub_post_side.disable_parts') == '1')  : ?>
                <?php else :?>
                    <div class="author_quote clearfix"><?php echo get_avatar( get_the_author_meta('email'), '69' ); ?>
                        <div class="clearfix">
                            <h4><?php the_author_posts_link(); ?></h4>
                            <div class="social_icon small_i">
                                <?php if(get_the_author_meta('user_url')) : ?><a href="<?php echo the_author_meta('user_url'); ?>" class="author-social hm" rel="nofollow"><i class="fa fa-home"></i></a><?php endif; ?>
                                <?php if(get_the_author_meta('facebook')) : ?><a href="<?php echo the_author_meta('facebook'); ?>" class="author-social fb" rel="nofollow"><i class="fa fa-facebook"></i></a><?php endif; ?>
                                <?php if(get_the_author_meta('twitter')) : ?><a href="<?php echo the_author_meta('twitter'); ?>" class="author-social tw" rel="nofollow"><i class="fa fa-twitter"></i></a><?php endif; ?>
                                <?php if(get_the_author_meta('google')) : ?><a href="<?php echo the_author_meta('google'); ?>?rel=author" class="author-social gp" rel="nofollow"><i class="fa fa-google-plus"></i></a><?php endif; ?>
                                <?php if(get_the_author_meta('tumblr')) : ?><a href="<?php echo the_author_meta('tumblr'); ?>" class="author-social tm" rel="nofollow"><i class="fa fa-tumblr"></i></a><?php endif; ?>
                                <?php if(get_the_author_meta('instagram')) : ?><a href="<?php echo the_author_meta('instagram'); ?>" class="author-social ins" rel="nofollow"><i class="fa fa-instagram"></i></a><?php endif; ?>
                                <?php if(get_the_author_meta('vkontakte')) : ?><a href="<?php echo the_author_meta('vkontakte'); ?>" class="author-social vk" rel="nofollow"><i class="fa fa-vk"></i></a><?php endif; ?>
                                <?php if(get_the_author_meta('youtube')) : ?><a href="<?php echo the_author_meta('youtube'); ?>" class="author-social yt" rel="nofollow"><i class="fa fa-youtube"></i></a><?php endif; ?>
                             </div>
                            <?php if (the_author_meta('description') !='') :?><p><?php the_author_meta('description'); ?></p><?php endif;?>
                        </div>
                    </div>
                <?php endif; ?>               

                <?php if(rehub_option('rehub_disable_relative') =='1' || vp_metabox('rehub_post_side.disable_parts') == '1')  : ?>
                <?php else :?>
                    <?php get_template_part('inc/parts/related_posts'); ?>
                <?php endif; ?>                               

            <?php endwhile; endif; ?>

                <?php comments_template(); ?>

			</div>	
            <!-- /Main Side -->  

            <!-- Sidebar -->
            <?php if(vp_metabox('rehub_post_side.post_size') == 'full_post') : ?><?php else : ?><?php get_sidebar(); ?><?php endif; ?>
            <!-- /Sidebar --> 

        </div>
    </div>
    <!-- /CONTENT -->     

<!-- FOOTER -->
<?php get_footer(); ?>