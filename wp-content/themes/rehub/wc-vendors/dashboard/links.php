
<p class="wc_vendors_dash_links">
        <a href="<?php echo $shop_page; ?>" class="button"><?php echo _e( 'View Your Store', 'rehub_framework' ); ?></a>
        <a href="<?php echo $settings_page; ?>" class="button"><?php _e('Store Settings', 'rehub_framework') ;?></a>

<?php if ( $can_submit ) { ?>
                <a target="_TOP" href="<?php echo $submit_link; ?>" class="button"><?php _e('Add New Product', 'rehub_framework') ;?></a>
                <a target="_TOP" href="<?php echo $edit_link; ?>" class="button"><?php _e('Edit Products', 'rehub_framework') ;?></a>
<?php } ?>
