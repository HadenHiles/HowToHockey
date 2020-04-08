<article class="col_item offer_grid inf_scr_item"> 
    <div class="eq_height_inpost"><?php echo re_badge_create('ribbonleft'); ?> 
        <figure>
            <a href="<?php the_permalink();?>">
                <?php $img = get_post_thumb(); ?>
                <?php if($columns == '3_col') : ?>
                    <?php $params = array( 'width' => 210, 'crop' => false);?>
                <?php elseif($columns == '4_col') : ?>
                    <?php $params = array( 'width' => 210, 'crop' => false);?>
                <?php elseif($columns == '5_col') : ?>
                    <?php $params = array( 'width' => 180, 'crop' => false);?>  
                <?php elseif($columns == '6_col') : ?>
                    <?php $params = array( 'width' => 140, 'crop' => false);?>                     
                <?php else : ?>
                    <?php $params = array( 'width' => 210, 'crop' => false);?>                                      
                <?php endif ; ?>
                <?php if(!empty($img)) : ?>
                  <img src="<?php echo bfi_thumb( $img, $params ); ?>" alt="<?php the_title_attribute(); ?>" class="img_centered" />
                <?php else :?>
                  <img src="<?php $nothumb = get_template_directory_uri() . '/images/default/noimage_336_220.png'; echo $nothumb ;?>" alt="<?php the_title_attribute(); ?>" class="img_centered" />                    
                <?php endif ; ?>
            </a>
        </figure>
        <h4><a href="<?php the_permalink();?>"><?php the_title();?></a></h4>                                            
    	<?php rehub_create_btn('no') ;?>
    </div>
    <div class="top">
        <?php  
            $brand_url = get_post_meta( get_the_ID(), 'rehub_offer_logo_url', true );
            if (!empty ($brand_url)) {
                $term_brand_image = esc_url($brand_url);
            }   
            else {
                $term_brand_image ='';
            }
        ?>               
        <?php if (!empty($term_brand_image)) :?>
            <div class="brand_logo_small">   
                <img src="<?php $params = array( 'width' => 40); echo bfi_thumb( $term_brand_image, $params ); ?>" alt="<?php the_title_attribute(); ?>" />
            </div>
        <?php else :?>
            <?php $category = get_the_category(get_the_ID());  ?>
            <?php if ($category) {$first_cat = $category[0]->term_id; meta_small( false, $first_cat, false, false );} ?>            
        <?php endif; ?>     
    </div>    
</article>