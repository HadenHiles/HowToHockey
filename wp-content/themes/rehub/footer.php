<?php if(rehub_option('rehub_ads_infooter') != '') : ?><div class="content mediad_footer"><div class="clearfix"></div><div class="mediad megatop_mediad"><?php echo do_shortcode(rehub_option('rehub_ads_infooter')); ?></div><div class="clearfix"></div></div><?php endif; ?>
<?php if(rehub_option('rehub_footer_widgets')) : ?>
<div class="footer-bottom<?php if(rehub_option('rehub_footer_block') =='1') : ?> block_foot<?php endif;?>">
  <div class="container clearfix">
	<div class="footer_widget">
		<?php if ( is_active_sidebar( 'sidebar-2' ) ) : ?>
			<?php dynamic_sidebar( 'sidebar-2' ); ?>
		<?php else : ?>
			<p><?php _e('No widgets added. You can disable footer widget area in theme options - footer options', 'rehub_framework'); ?></p>
		<?php endif; ?> 
	</div>
	<div class="footer_widget">
		<?php if ( is_active_sidebar( 'sidebar-3' ) ) : ?>
			<?php dynamic_sidebar( 'sidebar-3' ); ?>
		<?php endif; ?> 
	</div>
	<div class="footer_widget last">
		<?php if ( is_active_sidebar( 'sidebar-4' ) ) : ?>
			<?php dynamic_sidebar( 'sidebar-4' ); ?>
		<?php endif; ?> 
	</div>		
  </div>
</div>
<?php endif; ?>
<footer<?php if(rehub_option('rehub_footer_block') =='1') : ?> class="block_foot"<?php endif;?> id='theme_footer'>
  <div class="container clearfix">
    <div class="left">
		<h3 class="copyright">&copy; <?php echo date('Y'); ?> How To Hockey</h3>
    </div>
    <div class="right"> <?php if(rehub_option('rehub_footer_logo')) : ?><img src="<?php echo rehub_option('rehub_footer_logo'); ?>" alt="<?php bloginfo( 'name' ); ?>" /><?php endif; ?></div>
  </div>
</footer>
<!-- FOOTER --> 
<?php if(rehub_option('rehub_analytics')) : ?><?php echo rehub_option('rehub_analytics'); ?><?php endif; ?>
<?php if(rehub_option('rehub_disable_totop') !='1')  : ?><span class="rehub_scroll" id="topcontrol" data-scrollto="#top_ankor"><i class="fa fa-chevron-up"></i></span><?php endif; ?>
<?php wp_footer(); ?>
</body>
<script>
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

  ga('create', 'UA-1077767-26', 'auto');
  ga('send', 'pageview');

</script>
</html>