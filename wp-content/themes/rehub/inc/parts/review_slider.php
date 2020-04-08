<?php  wp_enqueue_script('flexslider'); ?>
<?php $gallery_images = vp_metabox('rehub_post.review_post.0.rehub_review_slider_images'); $resizer = vp_metabox('rehub_post.review_post.0.rehub_review_slider_resize'); ?>
<div class="post_slider media_slider<?php if ($resizer =='1') :?> blog_slider<?php else :?> gallery_top_slider<?php endif ;?> loading"> 
    <ul class="slides">     <script src="//a.vimeocdn.com/js/froogaloop2.min.js"></script>
        <?php 
            foreach ($gallery_images as $gallery_img) {
        ?>
            <?php if(vp_metabox('rehub_post_side.post_size') == 'full_post') : ?>
                <?php if (!empty ($gallery_img['review_post_video'])) :?>
                    <li data-thumb="<?php echo parse_video_url($gallery_img['review_post_video'], 'hqthumb'); ?>" class="play3">
                        <?php echo parse_video_url($gallery_img['review_post_video'], 'embed', '1130', '604');?>
                    </li>                                            
                <?php else : ?>
                    <li data-thumb="<?php $params = array( 'width' => 116, 'height' => 116, 'crop' => true  ); echo bfi_thumb($gallery_img['review_post_image'], $params); ?>">
                        <?php if (!empty ($gallery_img['review_post_image_caption'])) :?><div class="bigcaption"><?php echo $gallery_img['review_post_image_caption']; ?></div><?php endif;?>
                        <?php if (!empty ($gallery_img['review_post_image_url'])) :?><a href="<?php echo esc_url($gallery_img['review_post_image_url']); ?>" target="_blank" rel="nofollow"><?php endif;?>
                        <img src="<?php if ($resizer =='1') {$params = array( 'width' => 1130);} else {$params = array( 'width' => 1130, 'height' => 604, 'crop' => true    );}; echo bfi_thumb($gallery_img['review_post_image'], $params); ?>" />
                        <?php if (!empty ($gallery_img['review_post_image_url'])) :?></a><?php endif;?>
                    </li>                                           
                <?php endif; ?>                                                                                       
            <?php else : ?>
                <?php if (!empty ($gallery_img['review_post_video'])) :?>
                    <li data-thumb="<?php echo parse_video_url($gallery_img['review_post_video'], 'hqthumb'); ?>" class="play3">
                        <?php echo parse_video_url($gallery_img['review_post_video'], 'embed', '765', '478');?>
                    </li>                                            
                <?php else : ?>
                    <li data-thumb="<?php $params = array( 'width' => 80, 'height' => 80, 'crop' => true  ); echo bfi_thumb($gallery_img['review_post_image'], $params); ?>">
                        <?php if (!empty ($gallery_img['review_post_image_caption'])) :?><div class="bigcaption"><?php echo $gallery_img['review_post_image_caption']; ?></div><?php endif;?>
                        <?php if (!empty ($gallery_img['review_post_image_url'])) :?><a href="<?php echo esc_url($gallery_img['review_post_image_url']); ?>" target="_blank" rel="nofollow"><?php endif;?>
                        <img src="<?php if ($resizer =='1') {$params = array( 'width' => 765);} else {$params = array( 'width' => 765, 'height' => 478, 'crop' => true    );};echo bfi_thumb($gallery_img['review_post_image'], $params); ?>" />
                        <?php if (!empty ($gallery_img['review_post_image_url'])) :?></a><?php endif;?>
                    </li>                                            
                <?php endif; ?>                                                                                            
            <?php endif; ?>
        <?php
            }
        ?>
    </ul>
</div>   