<!DOCTYPE html>
<!--[if IE 8]>    <html class="ie8" <?php language_attributes(); ?>> <![endif]-->
<!--[if IE 9]>    <html class="ie9" <?php language_attributes(); ?>> <![endif]-->
<!--[if (gt IE 9)|!(IE)] <?php language_attributes(); ?>><![endif]-->
<html <?php language_attributes(); ?>>
<head>

<!-- Google Tag Manager -->
<script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
})(window,document,'script','dataLayer','GTM-KK884WV');</script>
<!-- End Google Tag Manager -->

<meta charset="utf-8" />
<meta name="viewport" content="width=device-width" />
<meta name="google-site-verification" content="UvlFPaJM2oRDbYsTuArxm21-IfE7EHgdUMrbucZK-as" />
<!-- feeds & pingback -->
<link rel="profile" href="http://gmpg.org/xfn/11" />
<link rel="pingback" href="<?php bloginfo( 'pingback_url' ); ?>" />
<!--[if lt IE 9]><script src="<?php echo get_template_directory_uri(); ?>/js/html5shiv.js"></script><![endif]-->	
<?php wp_head(); ?>
<?php if(rehub_option('rehub_custom_css')) : ?><style><?php echo rehub_option('rehub_custom_css'); ?></style><?php endif; ?>
</head>
<body <?php body_class(); ?>>

<!-- Google Tag Manager (noscript) -->
<noscript><iframe src="https://www.googletagmanager.com/ns.html?id=GTM-KK884WV"
height="0" width="0" style="display:none;visibility:hidden"></iframe></noscript>
<!-- End Google Tag Manager (noscript) -->

<?php 
    if (rehub_option('header_topline_style') == '0') {
        $header_topline_style = ' white_style';
    }
    elseif (rehub_option('header_topline_style') == '1') {
        $header_topline_style = ' dark_style';
    }
    else {
        $header_topline_style = ' white_style';
    }    
?>
<?php 
    if (rehub_option('header_logoline_style') == '0') {
        $header_logoline_style = 'white_style';
    }
    elseif (rehub_option('header_logoline_style') == '1') {
        $header_logoline_style = 'dark_style';
    }
    else {
        $header_logoline_style = 'white_style';
    }    
?>
<?php 
    if (rehub_option('header_menuline_style') == '0') {
        $header_menuline_style = ' white_style';
    }
    elseif (rehub_option('header_menuline_style') == '1') {
        $header_menuline_style = ' dark_style';
    }
    else {
        $header_menuline_style = ' dark_style';
    }    
?>
<?php get_template_part('inc/parts/branded_bg'); ?>
<?php if(rehub_option('rehub_ads_megatop') !='') : ?>
	<div class="megatop_wrap">
		<div class="mediad megatop_mediad">
			<?php echo do_shortcode(rehub_option('rehub_ads_megatop')); ?>
		</div>
	</div>
<?php endif ;?>	
<!-- HEADER -->
<header id="main_header" class="<?php echo $header_logoline_style;?>">
<div class="header_wrap<?php if(rehub_option('rehub_header_style') =='header_five') : ?> header_menu_row<?php endif; ?>">
    <div id="top_ankor"></div>
    <?php if(rehub_option('rehub_header_top') !='1')  : ?>  

        <!-- top -->  
        <div class="header_top_wrap<?php echo $header_topline_style;?>">

            <div class="header-top clearfix">    

                <?php if(has_nav_menu('user_logged_in_menu') && is_user_logged_in() && rehub_option('rehub_logged_enable_intop') == '1'): ?>
                    <?php wp_nav_menu( array( 'container_class' => 'top-nav', 'container' => 'div', 'theme_location' => 'user_logged_in_menu', 'fallback_cb' => 'add_top_menu_for_blank', 'depth' => '1', 'items_wrap' => '<i class="fa fa-bars re-top-menu-collapse"></i><ul id="%1$s" class="%2$s">%3$s</ul>'  ) ); ?> 
                <?php else :?>
                    <?php wp_nav_menu( array( 'container_class' => 'top-nav', 'container' => 'div', 'theme_location' => 'top-menu', 'fallback_cb' => 'add_top_menu_for_blank', 'depth' => '1', 'items_wrap' => '<i class="fa fa-bars re-top-menu-collapse"></i><ul id="%1$s" class="%2$s">%3$s</ul>'  ) ); ?>
                <?php endif;?>

                <div class="top-social"> 

                    <?php if(rehub_option('rehub_search_icon') == 'top') : ?>
                       <span class="icon-search-onclick icon-in-header-small"></span>
                    <?php endif; ?>

                    <?php if(rehub_option('rehub_login_icon') == 'top' && rehub_option('userlogin_enable') == '1') : ?>
                       <?php echo do_shortcode ('[wpsm_user_modal]');?>
                    <?php endif; ?>  

                    <!--
           			<?php if(rehub_option('rehub_header_social')) : ?>
                     	<?php rehub_get_social_links('small');?>  
                   	<?php endif; ?>  
                    -->

        <div class="social_icon small_i">

            <a class="fb hvr-push" rel="nofollow" href="https://www.facebook.com/howtohockey">
                <i class="fa fa-facebook"></i>
            </a>

            <a class="tw hvr-push" rel="nofollow" href="https://twitter.com/howtohockey">
                <i class="fa fa-twitter"></i>
            </a>

            <a class="ig hvr-push" rel="nofollow" href="https://instagram.com/howtohockey">
                <i class="fa fa-instagram"></i>
            </a>

            <a class="yt hvr-push" rel="nofollow" href="https://www.youtube.com/hockeymovement">
                <i class="fa fa-youtube"></i>
            </a>

            <a class="patreon hvr-push" rel="nofollow" href="https://www.patreon.com/hockeymovement">
                <i class="fa"></i>
            </a>            

        </div>


                    <?php global $woocommerce; ?>
                    <?php if ($woocommerce && rehub_option('exclude_cart_header') !='1') : ?><a class="cart-contents cart_count_<?php echo $woocommerce->cart->cart_contents_count; ?>" href="<?php echo $woocommerce->cart->get_cart_url(); ?>"><i class="fa fa-shopping-cart"></i> <?php _e( 'Cart', 'rehub_framework' ); ?> (<?php echo $woocommerce->cart->cart_contents_count; ?>) - <?php echo $woocommerce->cart->get_cart_total(); ?></a><?php endif; ?>
                
                </div>

            </div>

        </div>
        <!-- /top --> 

    <?php endif; ?>
    <!-- Logo section -->
    <div class="logo_section_wrap">
        <div class="logo-section <?php echo rehub_option('rehub_header_style') ;?>_style clearfix">


          <div class="goalie-buster-wrapper">
            <div class="goalie-buster">


             <a href="http://goaliebuster.com/"> 
             <img src="<?php echo get_stylesheet_directory_uri(); ?>/images/how-to-hockey-goalie-buster-training-course.jpg"</a>

            </div>  
          </div>  


            <div class="logo">
          		<?php if(rehub_option('rehub_logo')) : ?>
          			<a href="<?php echo home_url(); ?>"><img src="<?php echo rehub_option('rehub_logo'); ?>" alt="<?php bloginfo( 'name' ); ?>" /></a>
          		<?php elseif (rehub_option('rehub_text_logo')) : ?>
                <div class="textlogo"><?php echo rehub_option('rehub_text_logo'); ?></div>
                <div class="sloganlogo">
                    <?php if(rehub_option('rehub_text_slogan')) : ?><?php echo rehub_option('rehub_text_slogan'); ?><?php else : ?><?php bloginfo( 'description' ); ?><?php endif; ?>
                </div> 
                <?php else : ?>
          			<div class="textlogo"><?php bloginfo( 'name' ); ?></div>
                    <div class="sloganlogo"><?php bloginfo( 'description' ); ?></div>
          		<?php endif; ?> 
                <?php if( rehub_option( 'logo_retina' ) && rehub_option( 'logo_retina_width' ) && rehub_option( 'logo_retina_height' )): ?>
                    <script type="text/javascript">
                        jQuery(document).ready(function($) {
                        var retina = window.devicePixelRatio > 1 ? true : false;
                        if(retina) {
                            jQuery('header .logo img').attr('src', '<?php echo rehub_option( 'rehub_logo_retina' ); ?>');
                            jQuery('header .logo img').attr('width', '<?php echo rehub_option( 'rehub_logo_retina_width' ); ?>');
                            jQuery('header .logo img').attr('height', '<?php echo rehub_option( 'rehub_logo_retina_height' ); ?>');
                        }
                        });
                    </script>
                <?php endif; ?>      
            </div>

            <!--<?php if(rehub_option('rehub_header_style') == 'header_first') : ?><div class="search head_search"><?php get_search_form(); ?></div><?php endif; ?>-->
            
            <?php if(rehub_option('rehub_header_style') != 'header_third') : ?><?php if(rehub_option('rehub_ads_top')) : ?><div class="mediad"><?php echo do_shortcode(rehub_option('rehub_ads_top')); ?></div><?php endif; ?><?php endif; ?>
        </div>
    </div>
    <!-- /Logo section -->  
    <!-- Main Navigation -->
    <div class="main-nav<?php echo $header_menuline_style;?>">
        <?php wp_nav_menu( array( 'container_class' => 'top_menu', 'container' => 'nav', 'theme_location' => 'primary-menu', 'fallback_cb' => 'add_menu_for_blank', 'walker' => new Rehub_Walker ) ); ?>
        <div class="responsive_nav_wrap"></div>
    </div>
    <!-- /Main Navigation -->
</div>  
</header>
<?php get_template_part('inc/parts/branded_banner'); ?>
<?php get_template_part('inc/parts/news_ticker'); ?>