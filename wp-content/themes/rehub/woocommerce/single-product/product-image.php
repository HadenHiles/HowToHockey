<?php
/**
 * Single Product Image
 *
 * @author 		WooThemes
 * @package 	WooCommerce/Templates
 * @version	 2.0.14
 */

if ( ! defined( 'ABSPATH' ) ) exit; // Exit if accessed directly

global $post, $woocommerce, $product;

$attachment_ids = $product->get_gallery_attachment_ids();

if( rehub_option('woo_slider_enable') != '1' || empty ($attachment_ids)) {
	include WC()->plugin_path() . '/templates/single-product/product-image.php';
	return;
}
?>
<div class="images">
	<?php  wp_enqueue_script('flexslider');  ?>
	<div id="re_wooslider" class="flexslider loading re_wooslider"><i class="fa fa-spinner fa-pulse"></i>
		<ul class="slides">
			<?php
				$attachment_count   = count( $product->get_gallery_attachment_ids() );

				if ( $attachment_count > 0 ) {
					$gallery = '[product-gallery]';
				} else {
					$gallery = '';
				}			
			
				if ( has_post_thumbnail() ) {

					$image_title 		= esc_attr( get_the_title( get_post_thumbnail_id() ) );
					$image_link  		= wp_get_attachment_url( get_post_thumbnail_id() );
					$image	   		= get_the_post_thumbnail( $post->ID, apply_filters( 'single_product_large_thumbnail_size', 'shop_single' ), array(
						'title' => $image_title,
						'alt'	=> $image_title
						) );

					// Rehub Edit
					echo apply_filters( 'woocommerce_single_product_image_html', sprintf( '<li><a href="%s" itemprop="image" class="woocommerce-main-image zoom" title="%s" data-rel="prettyPhoto' . $gallery . '">%s</a></li>', $image_link, $image_title, $image ), $post->ID );

				} else {

					echo apply_filters( 'woocommerce_single_product_image_html', sprintf( '<li><img src="%s" alt="Placeholder" /></li>', wc_placeholder_img_src() ), $post->ID );

				}
				
				/**
				 * From product-thumbnails.php
				 */
				$attachment_ids = $product->get_gallery_attachment_ids();

				$loop = 0;
				// Rehub Edit
				//$columns = apply_filters( 'woocommerce_product_thumbnails_columns', 3 );

				foreach ( $attachment_ids as $attachment_id ) {

					// Rehub Edit
					/*
					$classes = array( 'zoom' );

					if ( $loop == 0 || $loop % $columns == 0 )
						$classes[] = 'first';

					if ( ( $loop + 1 ) % $columns == 0 )
						$classes[] = 'last';
					*/
					$classes[] = 'image-'.$attachment_id;

					$image_link = wp_get_attachment_url( $attachment_id );

					if ( ! $image_link )
						continue;

					// Rehub Edit
					// modified image size to shop_single from thumbnail
					$image	   = wp_get_attachment_image( $attachment_id, apply_filters( 'single_product_small_thumbnail_size', 'shop_single' ) );
					$image_class = esc_attr( implode( ' ', $classes ) );
					$image_title = esc_attr( get_the_title( $attachment_id ) );

					// Rehub Edit
					echo apply_filters( 'woocommerce_single_product_image_html', sprintf( '<li><a href="%s" itemprop="image" class="woocommerce-main-image zoom" title="%s" data-rel="prettyPhoto' . $gallery . '">%s</a></li>', $image_link, $image_title, $image ), $attachment_id, $post->ID, $image_class );
					//echo apply_filters( 'woocommerce_single_product_image_thumbnail_html', sprintf( '<a href="%s" class="%s" title="%s" data-rel="prettyPhoto[product-gallery]">%s</a>', $image_link, $image_class, $image_title, $image ), $attachment_id, $post->ID, $image_class );

					$loop++;
				}				
			?>
		</ul>
	</div>

	<?php do_action( 'woocommerce_product_thumbnails' ); ?>

</div>
