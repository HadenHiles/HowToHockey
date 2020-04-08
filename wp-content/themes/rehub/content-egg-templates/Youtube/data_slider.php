<?php
/*
 * Name: Slider
 * 
 */
?>

<?php  wp_enqueue_script('flexslider'); ?>

<div class="post_slider media_slider gallery_top_slider loading"> 
    <ul class="slides"><script src="//a.vimeocdn.com/js/froogaloop2.min.js"></script>
        <?php 
            foreach ($items as $item) {
        ?>

            <li data-thumb="<?php echo $item['img']; ?>" class="play3">
                <iframe width="765" height="478" src="https://www.youtube.com/embed/<?php echo $item['extra']['guid']; ?>?enablejsapi=1" frameborder="0" allowfullscreen></iframe>
            </li>                                                                                                                                        

        <?php
            }
        ?>
    </ul>
</div>