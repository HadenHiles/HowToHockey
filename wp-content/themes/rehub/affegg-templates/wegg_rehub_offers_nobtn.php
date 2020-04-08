<?php
/*
  Name: Offers without button
 */
?>

<?php wp_enqueue_style('eggrehub'); ?>

<div class="tabs-item"> 
    <?php $i=0; foreach ($items as $key => $item): ?>
        <?php $offer_price = str_replace(' ', '', $item['price']); if($offer_price =='0') {$offer_price = '';} ?>
        <?php $offer_price_old = str_replace(' ', '', $item['old_price']); if($offer_price_old =='0') {$offer_price_old = '';} ?>
        <?php $afflink = $item['url'] ;?>
        <?php $aff_thumb = $item['img'] ;?>
        <?php $offer_title = wp_trim_words( $item['title'], 10, '...' ); ?>
        <?php $i++;?>  
        <div class="clearfix">
            <figure>
                <a rel="nofollow" target="_blank" href="<?php echo esc_url($afflink) ?>"<?php echo $item['ga_event'] ?>>
                    <?php if (!empty($aff_thumb) ) :?>  
                        <img src="<?php $params = array( 'height' => 100 ); echo bfi_thumb( esc_attr($aff_thumb), $params ); ?>" alt="<?php echo esc_attr($offer_title); ?>" />
                    <?php else :?>
                        <img src="<?php echo get_template_directory_uri(); ?>/images/default/noimage_123_90.png" alt="<?php echo esc_attr($offer_title); ?>" />
                    <?php endif ;?>                                    
                </a>                
            </figure>
            <div class="detail">
                <h5>
                    <a rel="nofollow" target="_blank" href="<?php echo esc_url($afflink) ?>"<?php echo $item['ga_event'] ?>>
                        <?php echo esc_attr($offer_title); ?>
                    </a>                    
                </h5>
                <div class="rcnt_meta">
                    <div class="wooprice_count">
                        <span><?php echo $item['currency']; ?></span> <?php echo $offer_price ?>
                        <?php if(!empty($offer_price_old)) : ?>
                        <strike>
                            <span class="amount"><?php echo $offer_price_old ?></span>
                        </strike>
                        <?php endif ;?>                                
                    </div>
                    <div class="wooaff_tag">
                        <?php echo rehub_get_site_favicon($item['orig_url']); ?>                             
                    </div>                    
                </div>

            </div>
        </div>
    <?php endforeach; ?>
</div>