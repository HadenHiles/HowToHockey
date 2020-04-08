<?php
/*
 * Name: Small gallery
 * 
 */
?>

<?php $random_key = rand(0, 500);?>
<script>
jQuery(document).ready(function($) {
    'use strict'; 
    $('.pretty_woo a').attr('rel', 'prettyPhoto[rehub_product_gallery_<?php echo $random_key;?>]');
    $(".pretty_woo a[rel^='prettyPhoto']").prettyPhoto({social_tools:false});
});
</script>
<div class="pretty_woo">
    <?php wp_enqueue_script('prettyphoto');
        foreach ($items as $item) {
            ?> 
            <a href="<?php echo esc_attr($item['img']) ;?>"> 
            <img src="<?php echo esc_attr($item['img']) ;?>" alt="<?php echo esc_attr($item['title']); ?>" />  
            </a>
            <?php
        }
    ?>
</div>