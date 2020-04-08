<?php
/*
  Name: Carousel
 */
?>
<?php
//$product_price_update = get_post_meta( get_the_ID(), 'affegg_product_last_update', true );
//$best_price_value = $items[0]['price'];
//$best_price_currency = $items[0]['currency'];
?>
<?php wp_enqueue_script('carouFredSel'); ?>

<!-- Carousel -->
    <div class="home_carousel loading">    
        <div class="egg_carousel">
            <a href="/" class="controls prev"></a>

            <div class="container">
                <div class="carousel-block">
                <?php $i=0; foreach ($items as $key => $item): ?>
                    <?php $offer_price = str_replace(' ', '', $item['price']); if($offer_price =='0') {$offer_price = '';} ?>
                    <?php $offer_price_old = str_replace(' ', '', $item['old_price']); if($offer_price_old =='0') {$offer_price_old = '';} ?>
                    <?php $afflink = $item['url'] ;?>
                    <?php $aff_thumb = $item['img'] ;?>
                    <?php $offer_title = wp_trim_words( $item['title'], 8, '...' ); ?>
                    <?php $i++;?> 
                    <div class="preview tabcat">
                        <figure>                        
                            <a rel="nofollow" target="_blank" href="<?php echo esc_url($afflink) ?>"<?php echo $item['ga_event'] ?>>
                            <?php if(!empty($offer_price_old) && $offer_price_old !='0') : ?>
                                <span class="sale_a_proc">
                                    <?php   
                                        $offer_price_calc = intval(str_replace(',', '', $item['price']));
                                        $offer_price_old_calc = intval(str_replace(',', '', $item['old_price']));
                                        $sale_proc = 0 -(100 - ($offer_price_calc / $offer_price_old_calc) * 100); 
                                        $sale_proc = round($sale_proc); 
                                        echo $sale_proc; echo '%';
                                    ;?>
                                </span>
                            <?php endif ;?>                            
                                <?php if (!empty($aff_thumb) ) :?>  
                                    <img src="<?php $params = array( 'width' => 252 ); echo bfi_thumb( esc_attr($aff_thumb), $params ); ?>" alt="<?php echo esc_attr($offer_title); ?>" />
                                <?php else :?>
                                    <img src="<?php echo get_template_directory_uri(); ?>/images/default/noimage_336_220.png" alt="<?php echo esc_attr($offer_title); ?>" />
                                <?php endif ;?> 
                            </a>                           
                        </figure> 
                        <div class="text-oncarousel">
                            <h3><span class="count_carousel"><?php echo $i;?>. </span>                 
                                <a rel="nofollow" target="_blank" href="<?php echo esc_url($afflink) ?>"<?php echo $item['ga_event'] ?>>
                                    <?php echo esc_attr($offer_title); ?>
                                </a>
                            </h3>
                            <div class="egg_price_meta">
                                <?php if(!empty($offer_price)) : ?>
                                    <p itemprop="offers" itemscope itemtype="http://schema.org/Offer">
                                        <span>
                                            <span><?php echo $item['currency']; ?></span> <?php echo $offer_price ?>
                                            <?php if(!empty($offer_price_old)) : ?>
                                            <del>
                                                <span class="amount"><?php echo $offer_price_old ?></span>
                                            </del>
                                            <?php endif ;?>                                      
                                        </span> 
                                        <meta itemprop="price" content="<?php echo $item['price_raw'] ?>">
                                        <meta itemprop="priceCurrency" content="<?php echo $item['currency']; ?>">
                                        <?php if ($item['in_stock']): ?>
                                            <link itemprop="availability" href="http://schema.org/InStock">
                                        <?php endif ;?>                         
                                    </p>
                                <?php endif ;?>                                
                            </div>
                            <div class="aff_tag mt10 small_size"><?php echo rehub_get_site_favicon($item['orig_url']); ?></div>
                        </div>                       
                    </div>
                <?php endforeach; ?>
                </div>
            </div>
            <a href="/" class="controls next"></a>            
        </div>
    </div>     
<!-- End Carousel -->  
<div class="clearfix"></div>