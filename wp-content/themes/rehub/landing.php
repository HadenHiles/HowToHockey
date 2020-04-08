<?php
    
    /* Template Name: Landing */

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

          <div class="main-side clearfix<?php if (rehub_option('rehub_framework_archive_layout') == 'rehub_framework_archive_gridfull') : ?> full_width<?php endif ;?>">
            
            <h1 class="landing-header">What skill do you want to improve?</h1>

            <div id="landing-triptych">

                <ul>
                    <li>
                        <a href="<?php echo home_url() ?>/improve-your-stickhandling">
                            <img src="<?php echo get_stylesheet_directory_uri()?>/images/how-to-hockey-stickhandling-tips.jpg">
                        </a>
                    </li>
                    <li>
                        <a href="<?php echo home_url() ?>/improve-your-shooting">
                            <img src="<?php echo get_stylesheet_directory_uri()?>/images/how-to-hockey-shooting-tips.jpg">
                        </a>
                    </li>    
                    <li>
                        <a href="<?php echo home_url() ?>/improve-your-skating">
                            <img src="<?php echo get_stylesheet_directory_uri()?>/images/how-to-hockey-skating-tips.jpg">
                        </a>
                    </li>
                </ul>    

            </div>    


            <div class="hero-text">

                <?php if ( have_posts() ) : while ( have_posts() ) : the_post(); ?>       

                    <?php the_content(); ?>

                <?php endwhile; endif; ?> 

            </div>    


            <div class="heading"><h5><?php _e('Latest Posts', 'rehub_framework'); ?></h5></div>
            <?php
                $module_exclude = rehub_option('rehub_exclude_posts');
                if(($module_exclude) == 1) {
                        $exclude_posts = rehub_exclude_feature_posts();
                }
                else $exclude_posts ='';
                $paged = (get_query_var('paged')) ? get_query_var('paged') : 1;
                $args = array(
                  'paged' => $paged,
                  'post__not_in' => $exclude_posts
                );
            ?>

            <?php $query = new WP_Query( $args ); ?> 

                <?php if (rehub_option('rehub_framework_archive_layout') == 'rehub_framework_archive_grid') : ?>
                    <?php  wp_enqueue_script('masonry'); wp_enqueue_script('imagesloaded'); wp_enqueue_script('masonry_init'); ?>
                    <div class="masonry_grid_fullwidth two-col-gridhub">
                <?php elseif (rehub_option('rehub_framework_archive_layout') == 'rehub_framework_archive_gridfull') : ?>   
                    <?php  wp_enqueue_script('masonry'); wp_enqueue_script('imagesloaded'); wp_enqueue_script('masonry_init'); ?>
                    <div class="masonry_grid_fullwidth three-col-gridhub">                     
                <?php endif ;?>  

            <?php if ($query->have_posts()) : ?>

                <?php while ($query->have_posts()) : $query->the_post(); ?>

                        <?php get_template_part('inc/parts/query_type1'); ?>

                <?php endwhile; ?>

                <?php endif;?>

                <div class="pagination">    

                    <div class="nav-previous alignleft"><?php next_posts_link( 'Older posts' ); ?>?</div>
                    <div class="nav-next alignright"><?php previous_posts_link( 'Newer posts' ); ?>?</div>
                    
                    <?php rehub_pagination(); ?>


                </div>


            <div class="clearfix"></div>
            
            
            <?php wp_reset_query(); ?>

        </div>	

        <!-- /Main Side -->

        <?php if (rehub_option('rehub_framework_archive_layout') != 'rehub_framework_archive_gridfull') : ?>
            
            <!-- Sidebar -->

            <?php get_sidebar(); ?>

            <!-- /Sidebar --> 

        <?php endif ;?>

    </div>

</div>

<!-- /CONTENT -->     

<!-- FOOTER -->

<?php get_footer(); ?>