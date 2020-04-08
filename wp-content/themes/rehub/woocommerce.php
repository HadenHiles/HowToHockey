<?php get_header(); ?>

    <?php if(rehub_option('rehub_news_ticker')) : ?>
    	<?php get_template_part('inc/parts/news_ticker'); ?>
    <?php endif; ?>

    <!-- CONTENT -->
    <div class="content"> 
		<div class="clearfix">
		      <!-- Main Side -->
              <div class="main-side page clearfix">

                <article class="post" id="page-<?php the_ID(); ?>">
	               <?php
                        /**
                         * woocommerce_before_main_content hook
                         *
                         * @hooked woocommerce_output_content_wrapper - 10 (outputs opening divs for the content)
                         * @hooked woocommerce_breadcrumb - 20
                         */
                        do_action( 'woocommerce_before_main_content' );
                    ?>       
                    <?php woocommerce_content(); ?> 
                
                </article>

			</div>	
            <!-- /Main Side --> 

            <?php if(is_single()) {
            $rehub_aff_post_ids = vp_metabox('rehub_framework_woo.review_woo_links');
            $rehub_woo_post_ids = vp_metabox('rehub_framework_woo.review_woo_list_links');
            $rehub_woodeals_short = vp_metabox('rehub_framework_woo.rehub_woodeals_short');  
            if (($rehub_aff_post_ids !='' || $rehub_woo_post_ids !='') && empty($rehub_woodeals_short)) {
            	echo '<div class="woo_sidebar_deals_links">';
            	woo_dealslinks_rehub();
            	echo '</div>';
            }}; ?>
            <!-- Sidebar -->
            <?php get_sidebar(); ?>
            <!-- /Sidebar --> 

        </div>
    </div>
    <!-- /CONTENT -->     

<!-- FOOTER -->
<?php get_footer(); ?>