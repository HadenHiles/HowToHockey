<?php


/*-----------------------------------------------------------------------------------*/
# 	User rating function
/*-----------------------------------------------------------------------------------*/

add_action('wp_ajax_nopriv_rehub_rate_post', 'rehub_rate_post');
add_action('wp_ajax_rehub_rate_post', 'rehub_rate_post');
if( !function_exists('rehub_rate_post') ) {
function rehub_rate_post(){
	global $user_ID;

	if( rehub_option('type_user_review') == 'none' || ( !empty($user_ID) && rehub_option('allowtorate') == 'guests' ) ||	( empty($user_ID) && rehub_option('allowtorate') == 'users' ) ){
		return false ;
	}else{
		$count = $rating = $rate = 0;
		$postID = $_REQUEST['post'];
		$rate = abs($_REQUEST['value']);
		if($rate > 5 ) $rate = 5;

		if( is_numeric( $postID ) ){
			$rating = get_post_meta($postID, 'rehub_user_rate' , true);
			$count = get_post_meta($postID, 'rehub_users_num' , true);
			if( empty($count) || $count == '' ) $count = 0;

			$count++;
			$total_rate = $rating + $rate;
			$total = round($total_rate/$count , 2);
			if ( $user_ID ) {
				$user_rated = get_the_author_meta( 'rehub_rated', $user_ID  );

				if( empty($user_rated) ){
					$user_rated[$postID] = $rate;

					update_user_meta( $user_ID, 'rehub_rated', $user_rated );
					update_post_meta( $postID, 'rehub_user_rate', $total_rate );
					update_post_meta( $postID, 'rehub_users_num', $count );

					echo $total;
				}
				else{
					if( !array_key_exists($postID , $user_rated) ){
						$user_rated[$postID] = $rate;
						update_user_meta( $user_ID, 'rehub_rated', $user_rated );
						update_post_meta( $postID, 'rehub_user_rate', $total_rate );
						update_post_meta( $postID, 'rehub_users_num', $count );
						echo $total;
					}
				}
			}else{
				$user_rated = $_COOKIE["rehub_rate_".$postID];
				if( empty($user_rated) ){
					setcookie( 'rehub_rate_'.$postID , $rate , time()+31104000 , '/');
					update_post_meta( $postID, 'rehub_user_rate', $total_rate );
					update_post_meta( $postID, 'rehub_users_num', $count );
				}
			}
		}
	}
    die;
}
}


/*-----------------------------------------------------------------------------------*/
# 	User results generating
/*-----------------------------------------------------------------------------------*/

if( !function_exists('rehub_get_user_rate') ) {
function rehub_get_user_rate(){
	global $post , $user_ID;
	$disable_rate = false ;

	if( rehub_option('type_user_review') == 'none' )
		return false;

	if( ( !empty($user_ID) && rehub_option('allowtorate') == 'guests' ) || ( empty($user_ID) && rehub_option('allowtorate') == 'users' ) )
		$disable_rate = true ;

	if( !empty($disable_rate) ){
		$no_rate_text = __( 'No Ratings Yet!', 'rehub_framework' );
		$rate_active = false ;
	}
	else{
		$no_rate_text = __( 'Be the first one!' , 'rehub_framework' );
		$rate_active = ' user-rate-active' ;
	}

	$image_style ='stars';

	$rate = get_post_meta( $post->ID , 'rehub_user_rate', true );
	$count = get_post_meta( $post->ID , 'rehub_users_num', true );
	if( !empty($rate) && !empty($count)){
		$total = (($rate/$count)/5)*100;
		$total_users_score = round($rate/$count,2);
	}else{
		$total_users_score = $total = $count = 0;
	}

	if ( $user_ID ) {
		$user_rated = get_the_author_meta( 'rehub_rated' , $user_ID ) ;
		if( !empty($user_rated) && is_array($user_rated) && array_key_exists($post->ID , $user_rated) ){
			$user_rate = round( ($user_rated[$post->ID]*100)/5 , 1);
			return $output = '<div class="star"><span class="title_stars"><strong>'.__( "Your Rating:" , "rehub_framework" ) .' </strong> <span class="userrating-score">'.$user_rated[$post->ID].'</span> <small>(<span class="userrating-count">'.$count.'</span> '.__( "votes" , "rehub_framework" ) .')</small> </span><div data-rate="'. $user_rate .'" class="rate-post-'.$post->ID.' user-rate rated-done" title=""><span class="user-rate-image post-norsp-rate '.$image_style.'-rate"><span style="width:'. $total .'%"></span></span></div><div class="userrating-clear"></div></div>';
		}
	}else{
		$user_rate = (!empty($_COOKIE["rehub_rate_".$post->ID])) ? $_COOKIE["rehub_rate_".$post->ID] : '';

		if( !empty($user_rate) ){
			return $output = '<div class="star"><span class="title_stars"><strong>'.__( "Your Rating:" , "rehub_framework" ) .' </strong> <span class="userrating-score">'.$user_rate.'</span> <small>(<span class="userrating-count">'.$count.'</span> '.__( "votes" , "rehub_framework" ) .')</small> </span><div class="rate-post-'.$post->ID.' user-rate rated-done" title=""><span class="user-rate-image post-norsp-rate '.$image_style.'-rate"><span style="width:'. $total .'%"></span></span></div><div class="userrating-clear"></div></div>';
		}

	}
	if( $total == 0 && $count == 0)
		return $output = '<div class="star"><span class="title_stars"><strong>'.__( "User Rating:" , "rehub_framework" ) .' </strong> <span class="userrating-score"></span> <small>'.$no_rate_text.'</small> </span><div data-rate="'. $total .'" data-id="'.$post->ID.'" class="rate-post-'.$post->ID.' user-rate'.$rate_active.'"><span class="user-rate-image post-norsp-rate '.$image_style.'-rate"><span style="width:'. $total .'%"></span></span></div><div class="userrating-clear"></div></div>';
	elseif(rehub_option('type_schema_review') == 'user')
		return $output = '<div class="star"><div itemprop="aggregateRating" itemscope="" itemtype="http://schema.org/AggregateRating"><span class="title_stars"><strong>'.__( "User Rating:" , "rehub_framework" ) .' </strong> <span class="userrating-score" itemprop="ratingValue">'.$total_users_score.'</span> <small>(<span class="userrating-count" itemprop="reviewCount">'.$count.'</span> '.__( "votes" , "rehub_framework" ) .')</small> </span><div data-rate="'. $total .'" data-id="'.$post->ID.'" class="rate-post-'.$post->ID.' user-rate'.$rate_active.'"><span class="user-rate-image post-norsp-rate '.$image_style.'-rate"><span style="width:'. $total .'%"></span></span></div><div class="userrating-clear"></div></div></div>';
	else
		return $output = '<div class="star"><span class="title_stars"><strong>'.__( "User Rating:" , "rehub_framework" ) .' </strong> <span class="userrating-score">'.$total_users_score.'</span> <small>(<span class="userrating-count">'.$count.'</span> '.__( "votes" , "rehub_framework" ) .')</small> </span><div data-rate="'. $total .'" data-id="'.$post->ID.'" class="rate-post-'.$post->ID.' user-rate'.$rate_active.'"><span class="user-rate-image post-norsp-rate '.$image_style.'-rate"><span style="width:'. $total .'%"></span></span></div><div class="userrating-clear"></div></div>';
}
}

if( !function_exists('rehub_get_user_rate_criterias') ) {
function rehub_get_user_rate_criterias (){
	global $post;
	$postAverage = get_post_meta($post->ID, 'post_user_average', true);
	$userrevcount = get_post_meta($post->ID, 'post_user_raitings', true);
	if ($postAverage !='0' && $postAverage !='' ){
		$total = $postAverage*10;
		return $output = '<div class="star"><span class="title_stars"><strong>'.__( "User Rating:" , "rehub_framework" ) .' </strong> <span class="userrating-score">'.$postAverage.'/10</span> <small>(<span class="userrating-count">'.$userrevcount['criteria'][0]['count'].'</span> '.__( "votes" , "rehub_framework" ) .')</small></span><div class="user-rate"><span class="stars-rate"><span style="width: '.$total.'%;"></span></span></div></div>';
	}
	else {
		return $output = '<div class="star criterias_star"><span class="title_stars"><strong>'.__( "User Rating:" , "rehub_framework" ) .' </strong>'.__( "No Ratings Yet!" , "rehub_framework" ) .' </span><a href="#respond" class="rehub_scroll add_user_review_link color_link">'.__("Add your review", "rehub_framework").'</a></div>';
	}
}
}


//////////////////////////////////////////////////////////////////
// User get results
//////////////////////////////////////////////////////////////////

if( !function_exists('rehub_get_user_results') ) {
function rehub_get_user_results( $size = 'small', $words = 'no' ){
	global $post ;
	$rate = get_post_meta( $post->ID , 'rehub_user_rate', true );
	$count = get_post_meta( $post->ID , 'rehub_users_num', true );
	$postAverage = get_post_meta($post->ID, 'post_user_average', true);

	if ((rehub_option('type_user_review') == 'full_review') && ($postAverage !='0' && $postAverage !='' )){
		$total = $postAverage*10;
		?>
		<?php if ($words == 'yes') :?><strong><?php _e('User rating', 'rehub_framework'); ?>: </strong><?php endif ;?><div class="star-<?php echo $size ?>"><span class="stars-rate"><span style="width: <?php echo $total ?>%;"></span></span></div>
		<?php
	}
	elseif( rehub_option('type_user_review') == 'simple' && !empty($rate) && !empty($count)){
		$total = (($rate/$count)/5)*100;
		?>
		<?php if ($words == 'yes') :?><strong><?php _e('User rating', 'rehub_framework'); ?>: </strong><?php endif ;?><div class="star-<?php echo $size ?>"><span class="stars-rate"><span style="width: <?php echo $total ?>%;"></span></span></div>
		<?php
	}
	else{}
}
}

if( !function_exists('rehub_get_user_resultsedd') ) {
function rehub_get_user_resultsedd( $size = 'small' ){
	global $post ;
	$rate = get_post_meta( $post->ID , 'rehub_user_rate', true );
	$count = get_post_meta( $post->ID , 'rehub_users_num', true );
	if( !empty($rate) && !empty($count)){
		$total = (($rate/$count)/5)*100;
		?>
		<div class="star-<?php echo $size ?>"><span class="stars-rate"><span style="width: <?php echo $total ?>%;"></span></span></div>
		<?php
	}
	else{}
}
}

if( !function_exists('rehub_get_overall_score') ) {
function rehub_get_overall_score(){
	$thecriteria = vp_metabox('rehub_post.review_post.0.review_post_criteria');
	$manual_score = vp_metabox('rehub_post.review_post.0.review_post_score_manual');
	$score = 0; $total_counter = 0;

	if (!empty($thecriteria))  {
	    foreach ($thecriteria as $criteria) {
	    	$score += $criteria['review_post_score']; $total_counter ++;
	    }
	}
    if (!empty($manual_score))  {
    	$total_score = $manual_score;
    	return $total_score;
    }
    else {
		if( !empty( $score ) && !empty( $total_counter ) ) $total_score =  $score / $total_counter ;
		if( empty($total_score) ) $total_score = 0;
		$total_score = round($total_score,1);
		if (rehub_option('type_user_review') == 'full_review' && rehub_option('type_total_score') == 'average') {
			$userAverage = get_post_meta(get_the_ID(), 'post_user_average', true);
			if ($userAverage !='0' && $userAverage !='' ) {
				$total_score = ($total_score + $userAverage) / 2;
				$total_score = round($total_score,1);
			}
		}
		elseif (rehub_option('type_user_review') == 'simple' && rehub_option('type_total_score') == 'average') {
			$rate = get_post_meta(get_the_ID(), 'rehub_user_rate', true );
			$count = get_post_meta(get_the_ID(), 'rehub_users_num', true );
			if( !empty($rate) && !empty($count)){
				$userAverage = (($rate/$count)/5)*10;
				$total_score = ($total_score + $userAverage) / 2;
				$total_score = round($total_score,1);
			}
		}		
		return $total_score;
	}
}
}

if( !function_exists('rehub_get_overall_score_editor') ) {
function rehub_get_overall_score_editor(){
	$thecriteria = vp_metabox('rehub_post.review_post.0.review_post_criteria');
	$score = 0; $total_counter = 0;

    foreach ($thecriteria as $criteria) {

    	$score += $criteria['review_post_score']; $total_counter ++;
    }
		if( !empty( $score ) && !empty( $total_counter ) ) $total_score =  $score / $total_counter ;
		if( empty($total_score) ) $total_score = 0;
		$total_score = round($total_score,1);
		return $total_score;
}
}

add_action('save_post', 'rehub_save_post', 13);
if( !function_exists('rehub_save_post') ) {
function rehub_save_post( $post_id ){
	global $post;

	$rehub_meta_id = 'rehub_post';

	// check autosave
	if (defined('DOING_AUTOSAVE') && DOING_AUTOSAVE ) return $post_id;

	// make sure data came from our meta box, verify nonce
	$nonce = isset($_POST[$rehub_meta_id.'_nonce']) ? $_POST[$rehub_meta_id.'_nonce'] : NULL ;
	if (!wp_verify_nonce($nonce, $rehub_meta_id)) return $post_id;

	// check user permissions
	if ($_POST['post_type'] == 'page')
	{
		if (!current_user_can('edit_page', $post_id)) return $post_id;
	}
	else
	{
		if (!current_user_can('edit_post', $post_id)) return $post_id;
	}

	// authentication passed, process data
	$meta_data = isset( $_POST[$rehub_meta_id] ) ? $_POST[$rehub_meta_id] : NULL ;

	// if is review post, save data
	if( $meta_data['rehub_framework_post_type'] === 'review' )
	{
		$total_scores = rehub_get_overall_score();
		update_post_meta($post_id, 'rehub_review_overall_score', $total_scores); // save total score of review

		if( $meta_data['review_post'][0]['review_post_schema_type'] === 'review_aff_product' ){

			$rehub_aff_post_ids = vp_metabox('rehub_post.review_post.0.review_aff_product.0.review_aff_links');
			if (!empty($rehub_aff_post_ids)) {
				$rehub_aff_posts = get_posts(array(
					'post_type'        => 'thirstylink',
					'post__in' => $rehub_aff_post_ids,
				));
				$result = array();
				foreach($rehub_aff_posts as $aff_post) {
					$price = get_post_meta( $aff_post->ID, 'rehub_aff_price', true );
					$price = rehub_price_clean($price); 
					$result[] = $price;
				};
				if (!empty($result)) {
					$min_aff_price = min($result);
					update_post_meta($post_id, 'rehub_min_aff_price', $min_aff_price); // save minimal price of price range affiliate links
				}
			}

		}

		if( $meta_data['review_post'][0]['review_post_schema_type'] === 'review_post_review_product' ){
			$rehub_aff_post_link = vp_metabox('rehub_post.review_post.0.review_post_product.0.review_aff_link');
			if (!empty($rehub_aff_post_link)) {
				$linkpost = get_post($rehub_aff_post_link);
				$product_price = get_post_meta( $linkpost->ID, 'rehub_aff_price', true );
			}
			else {
				$product_price = vp_metabox('rehub_post.review_post.0.review_post_product.0.review_post_product_price');
			}
			$product_price = rehub_price_clean($product_price); 
			update_post_meta($post_id, 'rehub_main_product_price', $product_price);	// save value of product price
		}

	}
}
}


/*-----------------------------------------------------------------------------------*/
# 	Review box generating
/*-----------------------------------------------------------------------------------*/

if( !function_exists('rehub_get_review') ) {
function rehub_get_review(){

    ?>
    <?php $schema = (rehub_option('type_schema_review') == 'editor') ? ' itemtype="http://schema.org/Review" itemscope="" itemprop="review"' : '';?>
    <?php $overal_score = rehub_get_overall_score(); $postAverage = get_post_meta(get_the_ID(), 'post_user_average', true); ?>
	<div class="rate_bar_wrap<?php if ((rehub_option('type_user_review') == 'full_review') && ($postAverage !='0' && $postAverage !='' )) {echo ' two_rev';} ?><?php if (rehub_option('color_type_review') == 'multicolor') {echo ' colored_rate_bar';} ?>"<?php echo $schema;?>>
		<?php if (rehub_option('type_schema_review') == 'editor') :?>
		    <div itemtype="http://schema.org/Thing" itemscope="" itemprop="itemReviewed">                            
		        <div style="display:none" itemprop="name"><?php the_title(); ?></div>
		    </div>			
			<div style="display:none" itemprop="reviewBody"><?php echo wp_kses_post(vp_metabox('rehub_post.review_post.0.review_post_summary_text')); ?></div>
	        <?php if ( get_the_author_meta( 'google' ) ) : ?>
	            <div class="vcard author disauthor" itemprop="author" itemscope itemtype="http://schema.org/Person"><strong class="fn" itemprop="name"><a href="<?php the_author_meta( 'google' ); ?>?rel=author">+<?php echo get_the_author(); ?></a></strong></div>
	        <?php else : ?>
	            <div class="vcard author disauthor" itemprop="author" itemscope itemtype="http://schema.org/Person"><strong class="fn" itemprop="name"><?php the_author_posts_link(); ?></strong></div>
	        <?php endif; ?>        
        <?php endif ;?> 		
		<?php if ($overal_score !='0') :?>
			<div class="review-top">				
			<?php if (rehub_option('type_schema_review') == 'user' && rehub_option('type_user_review') == 'full_review' && get_post_meta(get_the_ID(), 'post_user_raitings', true) !='') :?>
				<div class="overall-score" itemprop="aggregateRating" itemscope="" itemtype="http://schema.org/AggregateRating">
					<meta itemprop="worstRating" content="1" />
					<meta itemprop="bestRating" content="10" />
					<span class="overall r_score_<?php echo round($overal_score); ?>" itemprop="ratingValue"><?php echo round($overal_score, 1) ?></span>
					<span class="overall-text"><?php _e('Total Score', 'rehub_framework'); ?></span>
					<div class="overall-user-votes"><span itemprop="ratingCount"><?php $user_rates = get_post_meta(get_the_ID(), 'post_user_raitings', true); echo $user_rates['criteria'][0]['count'] ;?></span> <?php _e('reviews', 'rehub_framework'); ?></div>				
				</div>				
			<?php elseif (rehub_option('type_schema_review') == 'editor') :?>
				<div class="overall-score" itemtype="http://schema.org/Rating" itemscope="" itemprop="reviewRating">
					<meta itemprop="worstRating" content="1" />
					<meta itemprop="bestRating" content="10" />
					<span class="overall r_score_<?php echo round($overal_score); ?>" itemprop="ratingValue"><?php echo round($overal_score, 1) ?></span>
					<span class="overall-text"><?php _e('Total Score', 'rehub_framework'); ?></span>
				</div>			
			<?php else :?>
				<div class="overall-score">
					<span class="overall r_score_<?php echo round($overal_score); ?>"><?php echo round($overal_score, 1) ?></span>
					<span class="overall-text"><?php _e('Total Score', 'rehub_framework'); ?></span>
				</div>				
			<?php endif;?>	
				<div class="review-text">
					<span class="review-header"><?php echo vp_metabox('rehub_post.review_post.0.review_post_heading'); ?></span>
					<p>
						<?php echo wp_kses_post(vp_metabox('rehub_post.review_post.0.review_post_summary_text')); ?>
					</p>
				</div>
			</div>
		<?php endif ;?>

		<?php $thecriteria = vp_metabox('rehub_post.review_post.0.review_post_criteria'); $firstcriteria = $thecriteria[0]['review_post_name']; ?>

		<?php if ((rehub_option('type_user_review') == 'full_review') && ($postAverage !='0' && $postAverage !='' )) :?>

			<div class="rate_bar_wrap_two_reviews">
				<?php if($firstcriteria) : ?>
				<div class="review-criteria">
					<div class="l_criteria"><span class="score_val r_score_<?php echo round(rehub_get_overall_score_editor()); ?>"><?php echo rehub_get_overall_score_editor() ?></span><span class="score_tit"><?php _e('Editor\'s score', 'rehub_framework'); ?></span></div>
					<div class="r_criteria">
						<?php foreach ($thecriteria as $criteria) { ?>
						<?php $perc_criteria = $criteria['review_post_score']*10; ?>
						<div class="rate-bar clearfix" data-percent="<?php echo $perc_criteria; ?>%">
							<div class="rate-bar-title"><span><?php echo $criteria['review_post_name']; ?></span></div>
							<div class="rate-bar-bar r_score_<?php echo round($criteria['review_post_score']); ?>"></div>
							<div class="rate-bar-percent"><?php echo $criteria['review_post_score']; ?></div>
						</div>
						<?php } ?>
					</div>
				</div>
				<?php endif; ?>
				<?php $user_rates = get_post_meta(get_the_ID(), 'post_user_raitings', true); $usercriterias = $user_rates['criteria'];  ?>
				<div class="review-criteria user-review-criteria">
					<div class="l_criteria"><span class="score_val r_score_<?php echo round($postAverage); ?>"><?php echo round($postAverage, 1) ?></span><span class="score_tit"><?php _e('User\'s score', 'rehub_framework'); ?></span></div>
					<div class="r_criteria">
						<?php foreach ($usercriterias as $usercriteria) { ?>
						<?php $perc_criteria = $usercriteria['average']*10; ?>
						<div class="rate-bar user-rate-bar clearfix" data-percent="<?php echo $perc_criteria; ?>%">
							<div class="rate-bar-title"><span><?php echo $usercriteria['name']; ?></span></div>
							<div class="rate-bar-bar r_score_<?php echo round($usercriteria['average']); ?>"></div>
							<div class="rate-bar-percent"><?php echo $usercriteria['average']; ?></div>
						</div>
						<?php } ?>
					</div>
				</div>
			</div>

		<?php else :?>

			<?php if($firstcriteria) : ?>
				<div class="review-criteria">
					<?php foreach ($thecriteria as $criteria) { ?>
						<?php $perc_criteria = $criteria['review_post_score']*10; ?>
						<div class="rate-bar clearfix" data-percent="<?php echo $perc_criteria; ?>%">
							<div class="rate-bar-title"><span><?php echo $criteria['review_post_name']; ?></span></div>
							<div class="rate-bar-bar r_score_<?php echo round($criteria['review_post_score']); ?>"></div>
							<div class="rate-bar-percent"><?php echo $criteria['review_post_score']; ?></div>
						</div>
					<?php } ?>
				</div>
			<?php endif; ?>

		<?php endif ;?>

		<?php if (rehub_option('type_user_review') == 'simple') :?>
			<?php if ($overal_score !='0') :?>
				<div class="rating_bar"><?php echo rehub_get_user_rate() ; ?></div>
			<?php else :?>
				<div class="rating_bar no_rev"><?php echo rehub_get_user_rate() ; ?></div>
			<?php endif; ?>
		<?php elseif (rehub_option('type_user_review') == 'full_review') :?>
			<a href="#respond" class="rehub_scroll add_user_review_link"><?php _e("Add your review", "rehub_framework"); ?></a> <?php $comments_count = wp_count_comments(get_the_ID()); if ($comments_count->total_comments !='') :?><span class="add_user_review_link"> &nbsp;|&nbsp; </span><a href="#comments" class="rehub_scroll add_user_review_link"><?php _e("Read reviews and comments", "rehub_framework"); ?></a><?php endif;?>
		<?php endif; ?>

	</div>


<?php

}
}

if( !function_exists('rehub_get_offer') ) {
function rehub_get_offer(){
	?>
	<?php global $post ?>
    <?php if (vp_metabox('rehub_post.review_post.0.review_post_schema_type') == 'review_post_review_product') : ?>

		<?php $review_aff_link = vp_metabox('rehub_post.review_post.0.review_post_product.0.review_aff_link');

		if(function_exists('thirstyInit') && !empty($review_aff_link)) :?>
			<?php $linkpost = get_post($review_aff_link);
			if ($linkpost) : ?>
				<?php $attachments = get_posts( array(
		            'post_type' => 'attachment',
					'post_mime_type' => 'image',
		            'posts_per_page' => -1,
		            'post_parent' => $linkpost->ID,
		        ) );?>
				<?php $offer_price = get_post_meta( $linkpost->ID, 'rehub_aff_price', true ) ?>
				<?php $offer_desc = get_post_meta( $linkpost->ID, 'rehub_aff_desc', true ) ?>
				<?php $offer_btn_text = get_post_meta( $linkpost->ID, 'rehub_aff_btn_text', true ) ?>
				<?php $offer_price_old = get_post_meta( $linkpost->ID, 'rehub_aff_price_old', true ) ?>
				<?php $offer_coupon = get_post_meta( $linkpost->ID, 'rehub_aff_coupon', true ) ?>
				<?php $offer_coupon_date = get_post_meta( $linkpost->ID, 'rehub_aff_coupon_date', true ) ?>
				<?php $offer_coupon_mask = get_post_meta( $linkpost->ID, 'rehub_aff_coupon_mask', true ) ?>
	            <?php $offer_url = get_post_permalink($review_aff_link) ?>
	            <?php $offer_title = $linkpost->post_title ?>
	            <?php $term_list = wp_get_post_terms($linkpost->ID, 'thirstylink-category', array("fields" => "names"));?>
	            <?php $term_ids =  wp_get_post_terms($linkpost->ID, 'thirstylink-category', array("fields" => "ids")); if (!empty($term_ids)) {$term_brand = $term_ids[0]; $term_brand_image = get_option("taxonomy_term_$term_brand");}?>
	            <?php
	            if (!empty($attachments)) {$offer_thumb = wp_get_attachment_url( $attachments[0]->ID);}
	            elseif (!empty($term_brand_image['brand_image'])) {$offer_thumb = $term_brand_image['brand_image'];}
	            else {$offer_thumb ='';}
	            ?>

				<div class="rehub_feat_block table_view_block"><div class="block_with_coupon">
			        <?php if(!empty($offer_thumb) || (has_post_thumbnail())) : ?>
			            <div class="offer_thumb">
			            <a href="<?php echo $offer_url ?>" target="_blank">
			            	<?php if (!empty($offer_thumb) ) :?>
			            		<img src="<?php $params = array( 'width' => 120, 'height' => 90 ); echo bfi_thumb( $offer_thumb, $params ); ?>" alt="<?php the_title_attribute(); ?>" />
			            	<?php else :?>
			            		<?php $image_id = get_post_thumbnail_id($post->ID);  $image_offer_url = wp_get_attachment_url($image_id);?>
			            		<img src="<?php $params = array( 'width' => 120, 'height' => 90 ); echo bfi_thumb( $image_offer_url, $params ); ?>" alt="<?php the_title_attribute(); ?>" />
			            	<?php endif ;?>
			            </a>
			            </div>
			   		<?php endif ;?>
			   		<div class="desc_col">
			            <div class="offer_title"><?php echo esc_html($offer_title) ;?></div>
			            <p><?php echo wp_kses_post($offer_desc); ?></p>
			        </div>
			        <?php if ( !empty($offer_price) || !empty($term_list[0])) :?>
				        <div class="price_col">
				        	<?php if(!empty($offer_price)) : ?><p> <span class="price_count"><ins><?php echo esc_html($offer_price) ?></ins><?php if($offer_price_old !='') :?> <del><?php echo esc_html($offer_price_old) ; ?></del><?php endif ;?></span></p><?php endif ;?>
				        	<div class="aff_tag">
					            <?php if (!empty($term_brand_image['brand_image'])) :?>
					            	<img src="<?php $params = array( 'width' => 120, 'height' => 90 ); echo bfi_thumb( $term_brand_image['brand_image'], $params ); ?>" alt="<?php the_title_attribute(); ?>" />
					            <?php elseif (!empty($term_list[0])) :?>
					            	<?php echo $term_list[0]; ?>
					            <?php endif; ?>
				            </div>
				        </div>
			        <?php endif; ?>
			        <div class="buttons_col">
			            <div class="priced_block clearfix">
							<?php if(!empty($offer_coupon_date)) : ?>
								<?php
									$timestamp1 = strtotime($offer_coupon_date);
									$seconds = $timestamp1 - time();
									$days = floor($seconds / 86400);
									$seconds %= 86400;
				            		if ($days > 0) {
				            			$coupon_text = $days.' '.__('days left', 'rehub_framework');
				            			$coupon_style = '';
				            		}
				            		elseif ($days == 0){
				            			$coupon_text = __('Last day', 'rehub_framework');
				            			$coupon_style = '';
				            		}
				            		else {
				            			$coupon_text = __('Coupon is Expired', 'rehub_framework');
				            			$coupon_style = 'expired_coupon';
				            		}
								?>
							<?php endif ;?>
			                <div><a href="<?php echo $offer_url ?>" class="btn_offer_block" target="_blank" rel="nofollow"><?php if($offer_btn_text !='') :?><?php echo $offer_btn_text ; ?><?php elseif(rehub_option('rehub_btn_text') !='') :?><?php echo rehub_option('rehub_btn_text') ; ?><?php else :?><?php _e('Buy this item', 'rehub_framework') ?><?php endif ;?></a></div>
							<?php if(!empty($offer_coupon)) : ?>
								<?php wp_enqueue_script('zeroclipboard'); ?>
								<?php if ($offer_coupon_mask !='1') :?>
                                    <div class="rehub_offer_coupon not_masked_coupon <?php if(!empty($offer_coupon_date)) {echo $coupon_style ;} ?>" data-clipboard-text="<?php echo $offer_coupon ?>"><i class="fa fa-scissors fa-rotate-180"></i><span class="coupon_text"><?php echo $offer_coupon ?></span></div>
                                <?php else :?>
                                    <div class="rehub_offer_coupon masked_coupon <?php if(!empty($offer_coupon_date)) {echo $coupon_style ;} ?>" data-clipboard-text="<?php echo $offer_coupon ?>" data-codeid="<?php echo $linkpost->ID?>" data-dest="<?php echo $offer_url ?>"><?php if(rehub_option('rehub_mask_text') !='') :?><?php echo rehub_option('rehub_mask_text') ; ?><?php else :?><?php _e('Reveal coupon', 'rehub_framework') ?><?php endif ;?><i class="fa fa-external-link-square"></i></div>
                                <?php endif;?>
                            	<?php if(!empty($offer_coupon_date)) {echo '<div class="time_offer">'.$coupon_text.'</div>';} ?>
							<?php endif ;?>
			            </div>
			        </div>
				</div></div>
			<?php endif ?>

		<?php else :?>

            <?php $offer_price = vp_metabox('rehub_post.review_post.0.review_post_product.0.review_post_product_price') ?>
            <?php $offer_url = vp_metabox('rehub_post.review_post.0.review_post_product.0.review_post_product_url') ?>
            <?php $offer_title = vp_metabox('rehub_post.review_post.0.review_post_product.0.review_post_product_name') ?>
            <?php $offer_thumb = vp_metabox('rehub_post.review_post.0.review_post_product.0.review_post_product_thumb') ?>
            <?php $offer_desc = vp_metabox('rehub_post.review_post.0.review_post_product.0.review_post_product_desc') ?>
            <?php $offer_btn_text = vp_metabox('rehub_post.review_post.0.review_post_product.0.review_post_btn_text') ?>
            <?php $offer_price_old = vp_metabox('rehub_post.review_post.0.review_post_product.0.review_post_product_price_old') ?>
            <?php $offer_coupon = vp_metabox('rehub_post.review_post.0.review_post_product.0.review_post_product_coupon') ?>
            <?php $offer_coupon_date = vp_metabox('rehub_post.review_post.0.review_post_product.0.review_post_coupon_date') ?>

			<div class="rehub_feat_block table_view_block"><div class="block_with_coupon">
		        <?php if(!empty($offer_thumb) || (has_post_thumbnail())) : ?>
		            <div class="offer_thumb">
		            <a href="<?php echo $offer_url ?>" target="_blank">
		            	<?php if (!empty($offer_thumb) ) :?>
		            		<img src="<?php $params = array( 'width' => 120, 'height' => 90 ); echo bfi_thumb( $offer_thumb, $params ); ?>" alt="<?php the_title_attribute(); ?>" />
		            	<?php else :?>
		            		<?php $image_id = get_post_thumbnail_id($post->ID);  $image_offer_url = wp_get_attachment_url($image_id);?>
		            		<img src="<?php $params = array( 'width' => 120, 'height' => 90 ); echo bfi_thumb( $image_offer_url, $params ); ?>" alt="<?php the_title_attribute(); ?>" />
		            	<?php endif ;?>
		            </a>
		            </div>
		   		<?php endif ;?>
		   		<div class="desc_col">
		            <div class="offer_title"><?php echo esc_html($offer_title) ;?></div>
		            <p><?php echo wp_kses_post($offer_desc); ?></p>
		        </div>
		        <?php if(!empty($offer_price)) : ?>
		        	<div class="price_col">
		        		<p><span class="price_count"><ins><?php echo esc_html($offer_price) ?></ins><?php if($offer_price_old !='') :?> <del><?php echo esc_html($offer_price_old) ; ?></del><?php endif ;?></span></p>
		        	</div>
		        <?php endif ;?>
		        <div class="buttons_col">
		            <div class="priced_block clearfix">
						<?php if(!empty($offer_coupon_date)) : ?>
							<?php
								$timestamp1 = strtotime($offer_coupon_date);
								$seconds = $timestamp1 - time();
								$days = floor($seconds / 86400);
								$seconds %= 86400;
			            		if ($days > 0) {
			            			$coupon_text = $days.' '.__('days left', 'rehub_framework');
			            			$coupon_style = '';
			            		}
			            		elseif ($days == 0){
			            			$coupon_text = __('Last day', 'rehub_framework');
			            			$coupon_style = '';
			            		}
			            		else {
			            			$coupon_text = __('Coupon is Expired', 'rehub_framework');
			            			$coupon_style = 'expired_coupon';
			            		}
							?>
						<?php endif ;?>

		                <div><a href="<?php echo $offer_url ?>" class="btn_offer_block" target="_blank" rel="nofollow"><?php if($offer_btn_text !='') :?><?php echo $offer_btn_text ; ?><?php elseif(rehub_option('rehub_btn_text') !='') :?><?php echo rehub_option('rehub_btn_text') ; ?><?php else :?><?php _e('Buy this item', 'rehub_framework') ?><?php endif ;?></a></div>
		            	<?php if(!empty($offer_coupon)) : ?>
		            		<?php wp_enqueue_script('zeroclipboard'); ?>
							<div class="rehub_offer_coupon not_masked_coupon <?php if(!empty($offer_coupon_date)) {echo $coupon_style ;} ?>" data-clipboard-text="<?php echo $offer_coupon ?>"><i class="fa fa-scissors fa-rotate-180"></i><span class="coupon_text"><?php echo $offer_coupon ?></span></div>
						<?php if(!empty($offer_coupon_date)) {echo '<div class="time_offer">'.$coupon_text.'</div>';} ?>
		            	<?php endif ;?>

		            </div>
		        </div>
	        </div></div>

	    <?php endif ;?>

    <div class="clearfix"></div>

    <?php endif ;?>

	<?php
}
}

if( !function_exists('rehub_get_aff_offer') ) {
function rehub_get_aff_offer(){
	?>
	<?php global $post ?>
    <?php if (vp_metabox('rehub_post.review_post.0.review_post_schema_type') == 'review_aff_product') : ?>
       	<div class="rehub_feat_block"><a name="aff-link-list"></a>
            <?php $aff_title = vp_metabox('rehub_post.review_post.0.review_aff_product.0.review_aff_product_name') ?>
            <?php $aff_thumb = vp_metabox('rehub_post.review_post.0.review_aff_product.0.review_aff_product_thumb') ?>
            <div class="aff_offer_desc"><?php if(!empty($aff_thumb) || (has_post_thumbnail())) : ?>
	            <div class="offer_thumb">
	            	<?php if (!empty($aff_thumb) ) :?>
	            		<img src="<?php $params = array( 'width' => 120, 'height' => 90 ); echo bfi_thumb( $aff_thumb, $params ); ?>" alt="<?php the_title_attribute(); ?>" />
	            	<?php else :?>
	            		<?php $image_id = get_post_thumbnail_id($post->ID);  $image_offer_url = wp_get_attachment_url($image_id);?>
	            		<img src="<?php $params = array( 'width' => 120, 'height' => 90 ); echo bfi_thumb( $image_offer_url, $params ); ?>" alt="<?php the_title_attribute(); ?>" />
	            	<?php endif ;?>
	            </div>
       		<?php endif ;?>
            <div class="offer_title"><?php echo esc_html($aff_title) ;?></div>
            <p><?php echo wp_kses_post(vp_metabox('rehub_post.review_post.0.review_aff_product.0.review_aff_product_desc')); ?></p>

			</div>
			<?php $rehub_aff_post_ids = vp_metabox('rehub_post.review_post.0.review_aff_product.0.review_aff_links');
			if(function_exists('thirstyInit') && !empty($rehub_aff_post_ids)) :?>
				<div class="clearfix"></div>
				<?php $min_aff_price_count = get_post_meta(get_the_ID(), 'rehub_min_aff_price', true); if ($min_aff_price_count !='') : ?>
					<p class="start_price"><?php _e('Pricing starts from ', 'rehub_framework') ?> <span itemprop="offers" itemscope itemtype="http://schema.org/AggregateOffer"><?php echo rehub_option('rehub_currency') ?><span itemprop="lowPrice"><?php echo $min_aff_price_count; ?></span></span></p>
				<?php endif ;?>
				<div class="aff_offer_links_heading"><?php _e('Choose best offer', 'rehub_framework') ?> &#8595;</div>
				<div class="aff_offer_links">
				<?php
				$rehub_aff_posts = get_posts(array(
					'post_type'        => 'thirstylink',
					'post__in' => $rehub_aff_post_ids,
	                'orderby' => 'post__in',
					'numberposts' => '-1'
				));
				$result_min = array(); //add array of prices
				foreach($rehub_aff_posts as $aff_post) { ?>
				<?php 	$attachments = get_posts( array(
		            'post_type' => 'attachment',
					'post_mime_type' => 'image',
		            'posts_per_page' => -1,
		            'post_parent' => $aff_post->ID,
	        	) );
				if (!empty($attachments)) {$aff_thumb_list = wp_get_attachment_url( $attachments[0]->ID );} else {$aff_thumb_list ='';}
				$term_list = wp_get_post_terms($aff_post->ID, 'thirstylink-category', array("fields" => "names"));
				$term_ids =  wp_get_post_terms($aff_post->ID, 'thirstylink-category', array("fields" => "ids")); if (!empty($term_ids)) {$term_brand = $term_ids[0]; $term_brand_image = get_option("taxonomy_term_$term_ids[0]");} else {$term_brand_image ='';}
				?>
				<div class="rehub_feat_block table_view_block">
					<?php if (get_post_meta( $aff_post->ID, 'rehub_aff_sticky', true) == '1') :?><div class="vip_corner"><span class="vip_badge"><i class="fa fa-thumbs-o-up"></i></span></div><?php endif ?>
					<div class="block_with_coupon">
						<div class="offer_thumb">
						<a href="<?php echo get_post_permalink($aff_post) ?>" target="_blank" rel="nofollow">
							<?php if (!empty($aff_thumb_list) ) :?>
		            			<img src="<?php $params = array( 'width' => 120, 'height' => 90 ); echo bfi_thumb( $aff_thumb_list, $params ); ?>" alt="<?php echo $aff_post->post_title; ?>" />
		            		<?php elseif (!empty($term_brand_image['brand_image'])) :?>
		            			<img src="<?php $params = array( 'width' => 120, 'height' => 90 ); echo bfi_thumb( $term_brand_image['brand_image'], $params ); ?>" alt="<?php echo $aff_post->post_title; ?>" />
		            		<?php else :?>
		            			<img src="<?php echo get_template_directory_uri(); ?>/images/default/noimage_100_70.png" alt="<?php echo $aff_post->post_title; ?>" />
		            		<?php endif?>
		            	</a>
						</div>
						<div class="desc_col">
							<div class="offer_title"><a href="<?php echo get_post_permalink($aff_post) ?>" target="_blank"><?php echo esc_html($aff_post->post_title); ?></a></div>
							<p><?php echo esc_html(get_post_meta( $aff_post->ID, 'rehub_aff_desc', true ));?></p>
							<?php $rehub_aff_review_related = get_post_meta( $aff_post->ID, "rehub_aff_rel", true ); if ( !empty($rehub_aff_review_related)) : ?>
								<a href="<?php echo $rehub_aff_review_related; ?>" target="_blank" class="color_link"><?php _e("Read review", "rehub_framework") ;?></a>
							<?php endif; ?>
						</div>
						<?php
						$product_price = get_post_meta( $aff_post->ID, 'rehub_aff_price', true );
						$offer_price_old = get_post_meta( $aff_post->ID, 'rehub_aff_price_old', true );
						if ( !empty($product_price) || !empty($term_list[0])) :?>
					        <div class="price_col">
								<?php
									if (!empty($product_price)) :
									$price_clean = rehub_price_clean($product_price); //Clean price from currence symbols
									$result_min[] = $price_clean;
								?>
									<p><span class="price_count"><ins><?php echo esc_html($product_price) ;?></ins><?php if($offer_price_old !='') :?> <del><?php echo esc_html($offer_price_old) ; ?></del><?php endif ;?></span></p>
								<?php endif ;?>
					        	<div class="aff_tag">
						            <?php if (!empty($term_brand_image['brand_image'])) :?>
						            	<img src="<?php $params = array( 'width' => 100, 'height' => 100 ); echo bfi_thumb( $term_brand_image['brand_image'], $params ); ?>" alt="<?php the_title_attribute(); ?>" />
						            <?php elseif (!empty($term_list[0])) :?>
						            	<?php echo $term_list[0]; ?>
						            <?php endif; ?>
					            </div>
					        </div>
				        <?php endif ;?>
						<div class="buttons_col">
							<div class="priced_block">
							<?php $offer_btn_text = get_post_meta( $aff_post->ID, 'rehub_aff_btn_text', true ) ?>
							<?php $offer_coupon = get_post_meta( $aff_post->ID, 'rehub_aff_coupon', true ) ?>
							<?php $offer_coupon_date = get_post_meta( $aff_post->ID, 'rehub_aff_coupon_date', true ) ?>
							<?php $offer_coupon_mask = get_post_meta( $aff_post->ID, 'rehub_aff_coupon_mask', true ) ?>
							<?php if(!empty($offer_coupon_date)) : ?>
								<?php
									$timestamp1 = strtotime($offer_coupon_date);
									$seconds = $timestamp1 - time();
									$days = floor($seconds / 86400);
									$seconds %= 86400;
				            		if ($days > 0) {
				            			$coupon_text = $days.' '.__('days left', 'rehub_framework');
				            			$coupon_style = '';
				            		}
				            		elseif ($days == 0){
				            			$coupon_text = __('Last day', 'rehub_framework');
				            			$coupon_style = '';
				            		}
				            		else {
				            			$coupon_text = __('Coupon is Expired', 'rehub_framework');
				            			$coupon_style = 'expired_coupon';
				            		}
								?>
							<?php endif ;?>
								<div><a class="btn_offer_block" href="<?php echo get_post_permalink($aff_post) ?>" target="_blank" rel="nofollow"><?php if($offer_btn_text !='') :?><?php echo $offer_btn_text ; ?><?php elseif(rehub_option('rehub_btn_text') !='') :?><?php echo rehub_option('rehub_btn_text') ; ?><?php else :?><?php _e('Buy this item', 'rehub_framework') ?><?php endif ;?></a></div>
								<?php if(!empty($offer_coupon)) : ?>
									<?php wp_enqueue_script('zeroclipboard'); ?>
									<?php if ($offer_coupon_mask !='1') :?>
	                                    <div class="rehub_offer_coupon not_masked_coupon <?php if(!empty($offer_coupon_date)) {echo $coupon_style ;} ?>" data-clipboard-text="<?php echo $offer_coupon ?>"><i class="fa fa-scissors fa-rotate-180"></i><span class="coupon_text"><?php echo $offer_coupon ?></span></div>
	                                <?php else :?>
	                                    <div class="rehub_offer_coupon masked_coupon <?php if(!empty($offer_coupon_date)) {echo $coupon_style ;} ?>" data-clipboard-text="<?php echo $offer_coupon ?>" data-codeid="<?php echo $aff_post->ID?>" data-dest="<?php echo get_post_permalink($aff_post) ?>"><?php if(rehub_option('rehub_mask_text') !='') :?><?php echo rehub_option('rehub_mask_text') ; ?><?php else :?><?php _e('Reveal coupon', 'rehub_framework') ?><?php endif ;?><i class="fa fa-external-link-square"></i></div>
	                                <?php endif;?>
	                            	<?php if(!empty($offer_coupon_date)) {echo '<div class="time_offer">'.$coupon_text.'</div>';} ?>
								<?php endif ;?>

							</div>
						</div>
					</div>
				</div>
				<?php
				}
				if (!empty($result_min)) {
 
					$min_aff_price_old = get_post_meta( get_the_ID(), 'rehub_min_aff_price', true );
					$min_aff_price = min($result_min); //Get minimal affiliate price
					if ( $min_aff_price !='' && $min_aff_price_old !='' && $min_aff_price != $min_aff_price_old ){
						update_post_meta(get_the_ID(), 'rehub_min_aff_price', $min_aff_price); // save minimal price of price range affiliate links
						update_post_meta(get_the_ID(), 'rehub_main_product_price', $min_aff_price);
					}
					elseif($min_aff_price !='' && $min_aff_price_old =='') {
						update_post_meta(get_the_ID(), 'rehub_min_aff_price', $min_aff_price);
						update_post_meta(get_the_ID(), 'rehub_main_product_price', $min_aff_price); 
					}					 
				}
				?>
				</div>
			<?php endif;?>
        </div>
        <div class="clearfix"></div>
    <?php endif ;?>
	<?php
}
}

if( !function_exists('rehub_get_woo_offer') ) {
function rehub_get_woo_offer($review_woo_link){
	?>
	<?php global $post ?>
	<?php global $woocommerce; if($woocommerce) :?>
		<?php
			$args = array(
				'post_type' 		=> 'product',
				'posts_per_page' 	=> 1,
				'no_found_rows' 	=> 1,
				'post_status' 		=> 'publish',
				'p'					=> $review_woo_link,

			);
		?>
		<?php $products = new WP_Query( $args ); if ( $products->have_posts() ) : ?>
    		<?php while ( $products->have_posts() ) : $products->the_post(); global $product?>

				<?php $offer_price = $product->get_price_html() ?>
	            <?php $woolink = ($product->product_type =='external') ? $product->add_to_cart_url() : get_post_permalink(get_the_ID()) ;?>
	            <?php $offer_title = $product->get_title() ?>
	            <?php $attributes = $product->get_attributes();  ?>
	            <?php if(rehub_option('rehub_btn_text') !='') :?><?php $btn_txt = rehub_option('rehub_btn_text') ; ?><?php else :?><?php $btn_txt = __('Buy this item', 'rehub_framework') ;?><?php endif ;?>
	            <?php $gallery_images = $product->get_gallery_attachment_ids(); ?>
	            <?php $woo_aff_links_inreview = (vp_metabox('rehub_framework_woo.review_woo_links') !='' || vp_metabox('rehub_framework_woo.review_woo_list_links') !='' || vp_metabox('rehub_framework_woo.rehub_woodeals_short') !='' ) ? '1' : ''; ?>
				<?php $term_ids =  wp_get_post_terms(get_the_ID(), 'product_tag', array("fields" => "ids")); 
					$brand_url = get_post_meta( get_the_ID(), 'rehub_woo_coupon_logo_url', true );
					if (!empty ($brand_url)) {
						$term_brand_image = esc_url($brand_url);
					}	
					elseif (!empty($term_ids)) {
						$term_brand = $term_ids[0]; 
						$term_brand_id = get_option("taxonomy_term_$term_ids[0]"); 
						$term_brand_image = ($term_brand_id['brand_image']) ? $term_brand_id['brand_image'] : '';
					}
					else {
						$term_brand_image ='';
					}
				?>
	            <?php $offer_coupon = get_post_meta( get_the_ID(), 'rehub_woo_coupon_code', true ) ?>
	            <?php $offer_coupon_date = get_post_meta( get_the_ID(), 'rehub_woo_coupon_date', true ) ?>
	            <?php $offer_coupon_mask = get_post_meta( get_the_ID(), 'rehub_woo_coupon_mask', true ) ?>
	            <?php $offer_coupon_url = esc_url( $product->add_to_cart_url() ); ?>
	            <?php $coupon_style = ''; if(!empty($offer_coupon_date)) : ?>
					<?php
					$timestamp1 = strtotime($offer_coupon_date);
					$seconds = $timestamp1 - time();
					$days = floor($seconds / 86400);
					$seconds %= 86400;
					if ($days > 0) {
					  $coupon_text = $days.' '.__('days left', 'rehub_framework');
					  $coupon_style = '';
					}
					elseif ($days == 0){
					  $coupon_text = __('Last day', 'rehub_framework');
					  $coupon_style = '';
					}
					else {
					  $coupon_text = __('Coupon is Expired', 'rehub_framework');
					  $coupon_style = 'expired_coupon';
					}
					?>
	          	<?php endif ;?>
				<?php $coupon_enabled_style = (!empty($offer_coupon_mask)) ? ' reveal_enabled '.$coupon_style.'' : ' '.$coupon_style.'' ?>					            
    			<div class="rehub_woo_review<?php echo $coupon_enabled_style ;?>">
    				<?php if (!empty ($attributes) || !empty ($gallery_images)) :?>
    					<ul class="rehub_woo_tabs_menu">
				            <li><?php _e('Product', 'rehub_framework') ?></li>
				            <?php if (!empty ($attributes)) :?><li><?php _e('Specification', 'rehub_framework') ?></li><?php endif ;?>
				            <?php if (!empty ($gallery_images)) :?><li><?php _e('Photos', 'rehub_framework') ?></li><?php endif ;?>
				            <?php if (!empty ($woo_aff_links_inreview)) :?><li class='woo_deals_tab'><?php _e('Deals', 'rehub_framework') ?></li><?php endif ;?>
						</ul>
						<?php endif ;?>
						<div class="rehub_feat_block table_view_block">
			            <div class="rehub_woo_review_tabs" style="display:table-row">
				            <div class="offer_thumb">
				            	<a href="<?php echo $woolink ;?>" target="_blank"><?php wpsm_thumb('med_thumbs') ;?></a>
				            </div>
							<div class="desc_col">
				            	<div class="offer_title"><a href="<?php echo $woolink ;?>" target="_blank"><?php echo esc_attr($offer_title) ;?></a></div>
				            	<p><?php kama_excerpt('maxchar=200'); ?></p>
				            	<p>
									<?php if (in_array( 'yith-woocommerce-compare/init.php', apply_filters( 'active_plugins', get_option( 'active_plugins' ) ) ) )  { ?>
                         				<?php echo do_shortcode('[yith_compare_button]'); ?>
									<?php } ?>
				            		<?php if (in_array( 'yith-woocommerce-wishlist/init.php', apply_filters( 'active_plugins', get_option( 'active_plugins' ) ) ) )  { ?>
                        				<?php echo do_shortcode('[yith_wcwl_add_to_wishlist]'); ?>
									<?php } ?>
								</p>
				            </div>
				            <div class="buttons_col">
					            <div class="priced_block clearfix">
					                <?php if(!empty($offer_price)) : ?><p><span class="price_count"><?php echo $offer_price ?></span></p><?php endif ;?>
					                <div>
					                	<?php if ($product->product_type =='external' && $product->add_to_cart_url() ==''  && !empty ($woo_aff_links_inreview)) :?>
					                		<a class='btn_offer_block choose_offer_woo' href="#"><?php _e('Prices', 'rehub_framework') ;?></a>
					                	<?php else :?>
					                        <?php if ( $product->is_in_stock() &&  $product->add_to_cart_url() !='') : ?>
					                         	<?php  echo apply_filters( 'woocommerce_loop_add_to_cart_link',
					    							sprintf( '<a href="%s" rel="nofollow" data-product_id="%s" data-product_sku="%s" class="btn_offer_block %s product_type_%s"%s>%s</a>',
					    							esc_url( $product->add_to_cart_url() ),
					    							esc_attr( $product->id ),
					    							esc_attr( $product->get_sku() ),
					    							$product->is_purchasable() && $product->is_in_stock() ? 'add_to_cart_button' : 'add_to_cart_button',
					    							esc_attr( $product->product_type ),
					    							$product->product_type =='external' ? ' target="_blank" rel="nofollow"' : '',
					    							esc_html( $product->add_to_cart_text() )
					    							),
					    						$product );?>
					                        <?php endif; ?>
            							<?php endif; ?>
							          	<?php if(!empty($offer_coupon)) : ?>
											<?php wp_enqueue_script('zeroclipboard'); ?>
											<?php if ($offer_coupon_mask !='1' && $offer_coupon_mask !='on') :?>
											  <div class="rehub_offer_coupon not_masked_coupon <?php if(!empty($offer_coupon_date)) {echo $coupon_style ;} ?>" data-clipboard-text="<?php echo $offer_coupon ?>"><i class="fa fa-scissors fa-rotate-180"></i><span class="coupon_text"><?php echo $offer_coupon ?></span></div>
											<?php else :?>
											  <div class="rehub_offer_coupon masked_coupon <?php if(!empty($offer_coupon_date)) {echo $coupon_style ;} ?>" data-clipboard-text="<?php echo $offer_coupon ?>" data-codeid="<?php echo $product->id ?>" data-dest="<?php echo $offer_coupon_url ?>"><?php if(rehub_option('rehub_mask_text') !='') :?><?php echo rehub_option('rehub_mask_text') ; ?><?php else :?><?php _e('Reveal coupon', 'rehub_framework') ?><?php endif ;?><i class="fa fa-external-link-square"></i></div>
											<?php endif;?>
											<?php if(!empty($offer_coupon_date)) {echo '<div class="time_offer">'.$coupon_text.'</div>';} ?>
							          	<?php endif ;?>
					                </div>
					            </div>
								<?php if (!empty($term_brand_image)) :?>
					                <div class="brand_logo_small mt10">
					                    <img src="<?php $params = array( 'width' => 50); echo bfi_thumb( $term_brand_image, $params ); ?>" alt="<?php the_title_attribute(); ?>" />
					                </div>
				                <?php endif; ?>
				            </div>
		        		</div>
		        		<?php if (!empty ($attributes)) :?>
				        	<div class="rehub_woo_review_tabs">
				     			<div><?php $product->list_attributes() ;?></div>

				        	</div>
			        	<?php endif ;?>
		        		<?php if (!empty ($gallery_images)) :?>
		        			<script>
		        			jQuery(document).ready(function($) {
								'use strict';
		        				$('.rehub_woo_review .pretty_woo a').attr('rel', 'prettyPhoto[rehub_product_gallery]');
								$(".rehub_woo_review .pretty_woo a[rel^='prettyPhoto']").prettyPhoto({social_tools:false});
							});
		        			</script>
				        	<div class="rehub_woo_review_tabs pretty_woo">
				     			<?php wp_enqueue_script('prettyphoto');
									foreach ($gallery_images as $gallery_img) {
										?>
										<?php $thumbfull = wp_get_attachment_link($gallery_img, array(100,100)); ?>
										<?php echo $thumbfull; ?>
										<?php
									}
								?>
				        	</div>
			        	<?php endif ;?>
			        	<?php if (!empty ($woo_aff_links_inreview)) :?>
			        		<div class="rehub_woo_review_tabs">
			        			<div class="woo_inreview_deals_links"><?php woo_dealslinks_rehub(); ;?></div>
			        		</div>
			        	<?php endif ;?>
		        	</div>
		        </div>
		        <div class="clearfix"></div>

			<?php //save clean price to post meta
                $price_clean = $product->get_price();
	            $offer_price_clean = rehub_price_clean($price_clean);				 
			 ?>		        

    		<?php endwhile; endif;  wp_reset_postdata(); ?>

		<?php //save clean price to post meta				 
			$offer_price_clean_old = get_post_meta( $post->ID, 'rehub_main_product_price', true );
			if ( $offer_price_clean !='' && $offer_price_clean_old !='' && $offer_price_clean != $offer_price_clean_old ){
				update_post_meta(get_the_ID(), 'rehub_main_product_price', $offer_price_clean); 
			}
			elseif($offer_price_clean !='' && $offer_price_clean_old =='') {
				update_post_meta(get_the_ID(), 'rehub_main_product_price', $offer_price_clean); 
			}
		 ?>

	<?php endif ;?>
	<?php
}
}

if( !function_exists('rehub_get_woo_list') ) {
function rehub_get_woo_list( $data_source = '', $type ='', $cat = '', $tag = '', $ids = '', $orderby = '', $order = '', $show = '', $show_coupons_only = ''){
?>

<?php
    if ($data_source == 'ids' && $ids !='') {
        $ids = explode(',', $ids);
        $args = array(
            'post__in' => $ids,
            'numberposts' => '-1',
            'orderby' => 'post__in',
            'post_type' => 'product',
            'ignore_sticky_posts'   => 1,
            'no_found_rows' => 1,
        );
    }
    else {
        $args = array(
            'post_type' => 'product',
            'posts_per_page'   => $show,
            'orderby' => $orderby,
            'order' => $order,
            'ignore_sticky_posts' => 1,
        );
        if ($data_source == 'cat' && $cat !='') {
            $cat = explode(',', $cat);
            $args['tax_query'] = array(array('taxonomy' => 'product_cat', 'terms' => $cat, 'field' => 'id'));
        }
        if ($data_source == 'tag' && $tag !='') {
            $tag = explode(',', $tag);
            $args['tax_query'] = array(array('taxonomy' => 'product_tag', 'terms' => $tag, 'field' => 'id'));
        }
        if ($data_source == 'type') {
            if($type =='featured') {$args['meta_query']=array(array('key' => '_featured', 'value' => 'yes'));}
            elseif($type =='sale') {
                $product_ids_on_sale = wc_get_product_ids_on_sale();
                $meta_query   = array();
                $meta_query[] = WC()->query->visibility_meta_query();
                $meta_query[] = WC()->query->stock_status_meta_query();
                $meta_query   = array_filter( $meta_query );
                $args['meta_query'] = $meta_query;
                $args['post__in'] = array_merge( array( 0 ), $product_ids_on_sale );
                $args['no_found_rows'] = 1;
            }
            elseif($type =='best_sale') {$args['meta_key']='total_sales'; $args['orderby']='meta_value_num';}
        }
    }
    if ($show_coupons_only == '1') {     
        $args['meta_query'][] = array(
            'key'     => 'rehub_woo_coupon_date',
            'value'   => date('Y-m-d'),
            'compare' => '>=',
        );
    } 
    if ($show_coupons_only == '2') {     
	    $args['meta_query'] = array(
	    	'relation' => 'OR',
	    	array(
	       		'key' => 'rehub_woo_coupon_date',
	       		'value' => date('Y-m-d'),
	       		'compare' => '>=',
	    	),
	    	array(
	       		'key' => 'rehub_woo_coupon_date',
	       		'compare' => 'NOT EXISTS',
	    	),	    	
		);
    } 	
    if ($show_coupons_only == '3') {     
        $args['meta_query'][] = array(
            'key'     => 'rehub_woo_coupon_date',
            'value'   => date('Y-m-d'),
            'compare' => '<',
        );
    }
    global $post; global $woocommerce; $backup=$post; $result_min = array(); //add array of prices
?>
<div class="aff_offer_links">
<?php $i=1; $wp_query = new WP_Query( $args ); if ( $wp_query->have_posts() ) : ?>
<?php while ( $wp_query->have_posts() ) : $wp_query->the_post();  global $product;  ?>

<?php $woolink = ($product->product_type =='external') ? $product->add_to_cart_url() : get_post_permalink(get_the_ID()) ;?>
<?php $term_ids =  wp_get_post_terms(get_the_ID(), 'product_tag', array("fields" => "ids")); 
	$brand_url = get_post_meta( get_the_ID(), 'rehub_woo_coupon_logo_url', true );
	if (!empty ($brand_url)) {
		$term_brand_image = esc_url($brand_url);
	}	
	elseif (!empty($term_ids)) {
		$term_brand = $term_ids[0]; 
		$term_brand_id = get_option("taxonomy_term_$term_ids[0]"); 
		$term_brand_image = ($term_brand_id['brand_image']) ? $term_brand_id['brand_image'] : '';
	}
	else {
		$term_brand_image ='';
	}
?>
<?php $offer_coupon = get_post_meta( get_the_ID(), 'rehub_woo_coupon_code', true ) ?>
<?php $offer_coupon_date = get_post_meta( get_the_ID(), 'rehub_woo_coupon_date', true ) ?>
<?php $offer_coupon_mask = get_post_meta( get_the_ID(), 'rehub_woo_coupon_mask', true ) ?>
<?php $offer_coupon_url = esc_url( $product->add_to_cart_url() ); ?>
<?php $coupon_style = ''; if(!empty($offer_coupon_date)) : ?>
    <?php
    $timestamp1 = strtotime($offer_coupon_date);
    $seconds = $timestamp1 - time();
    $days = floor($seconds / 86400);
    $seconds %= 86400;
    if ($days > 0) {
      	$coupon_text = $days.' '.__('days left', 'rehub_framework');
      	$coupon_style = '';
    }
    elseif ($days == 0){
      $coupon_text = __('Last day', 'rehub_framework');
      $coupon_style = '';
    }
    else {
      $coupon_text = __('Coupon is Expired', 'rehub_framework');
      $coupon_style = 'expired_coupon';
    }
    ?>
<?php endif ;?>
<?php $coupon_enabled_style = (!empty($offer_coupon_mask)) ? ' reveal_enabled '.$coupon_style.'' : ' '.$coupon_style.'' ?>
<div class="rehub_feat_block table_view_block<?php echo $coupon_enabled_style ;?>"><a name="woo-link-list"></a>
    <?php if ($product->is_on_sale()) : ?><div class="vip_corner"><span class="vip_badge sale_badge"><?php _e('Sale!', 'rehub_framework')?></span></div><?php endif ?>
    <div class="block_with_coupon">
        <div class="offer_thumb">
        <a href="<?php echo $woolink; ?>" target="_blank"<?php if ($product->product_type =='external'){echo ' rel="nofollow"';} ?>><?php wpsm_thumb( 'med_thumbs') ?></a>
        </div>
        <div class="desc_col">
            <div class="offer_title"><a href="<?php echo $woolink; ?>" target="_blank"<?php if ($product->product_type =='external'){echo ' rel="nofollow"';} ?>><?php the_title(); ?></a></div>
            <p>
            	<?php kama_excerpt('maxchar=150'); ?>
            	<?php $rehub_woo_review_related = get_post_meta( get_the_ID(), "review_woo_id", true ); if ( !empty($rehub_woo_review_related)) : ?>
                	<a href="<?php echo get_permalink($rehub_woo_review_related) ;?>" target="_blank" class="color_link"><?php _e("Read review", "rehub_framework") ;?></a>
                	<div class="clearfix"></div>
            	<?php endif; ?>
            </p>
            <p>
                <?php if (in_array( 'yith-woocommerce-compare/init.php', apply_filters( 'active_plugins', get_option( 'active_plugins' ) ) ) )  { ?>
                    <?php echo do_shortcode('[yith_compare_button]'); ?>
                <?php } ?>
                <?php if (in_array( 'yith-woocommerce-wishlist/init.php', apply_filters( 'active_plugins', get_option( 'active_plugins' ) ) ) )  { ?>
                    <?php echo do_shortcode('[yith_wcwl_add_to_wishlist]'); ?>
                <?php } ?>
            </p>
        </div>
            <div class="price_col">
                <?php if ($product->get_price() !='') : ?>
                <p><span class="price_count"><?php echo $product->get_price_html(); ?></span></p>
                <?php
                	$price_clean = $product->get_price();
	                $price_clean = rehub_price_clean($price_clean); 
					$result_min[] = $price_clean;
				?>
                <?php endif ;?>
                <?php if (!empty($term_brand_image)) :?>
                <div class="brand_logo_small">
                    <img src="<?php $params = array( 'width' => 50); echo bfi_thumb( $term_brand_image, $params ); ?>" alt="<?php the_title_attribute(); ?>" />
                </div>
                <?php endif; ?>
            </div>            
            <div class="buttons_col">
                <div class="priced_block">
                    <?php if ( $product->is_in_stock() &&  $product->add_to_cart_url() !='') : ?>
                        <?php  echo apply_filters( 'woocommerce_loop_add_to_cart_link',
                            sprintf( '<a href="%s" data-product_id="%s" data-product_sku="%s" class="btn_offer_block %s product_type_%s"%s%s>%s</a>',
                            esc_url( $product->add_to_cart_url() ),
                            esc_attr( $product->id ),
                            esc_attr( $product->get_sku() ),
                            $product->is_purchasable() && $product->is_in_stock() ? 'add_to_cart_button' : 'add_to_cart_button',
                            esc_attr( $product->product_type ),
                            $product->product_type =='external' ? ' target="_blank"' : '',
                            $product->product_type =='external' ? ' rel="nofollow"' : '',
                            esc_html( $product->add_to_cart_text() )
                            ),
                        $product );?>
                    <?php endif; ?>
                </div>
                <?php if(!empty($offer_coupon)) : ?>
                    <?php wp_enqueue_script('zeroclipboard'); ?>
                    <?php if ($offer_coupon_mask !='1' && $offer_coupon_mask !='on') :?>
                      <div class="rehub_offer_coupon not_masked_coupon <?php if(!empty($offer_coupon_date)) {echo $coupon_style ;} ?>" data-clipboard-text="<?php echo $offer_coupon ?>"><i class="fa fa-scissors fa-rotate-180"></i><span class="coupon_text"><?php echo $offer_coupon ?></span></div>
                    <?php else :?>
                      <div class="rehub_offer_coupon masked_coupon <?php if(!empty($offer_coupon_date)) {echo $coupon_style ;} ?>" data-clipboard-text="<?php echo $offer_coupon ?>" data-codeid="<?php echo $product->id ?>" data-dest="<?php echo $offer_coupon_url ?>"><?php if(rehub_option('rehub_mask_text') !='') :?><?php echo rehub_option('rehub_mask_text') ; ?><?php else :?><?php _e('Reveal coupon', 'rehub_framework') ?><?php endif ;?><i class="fa fa-external-link-square"></i></div>
                    <?php endif;?>
                    <?php if(!empty($offer_coupon_date)) {echo '<div class="time_offer">'.$coupon_text.'</div>';} ?>
                <?php endif ;?>
            </div>
    </div>
</div>
<?php $i++; endwhile; endif; wp_reset_postdata(); $post=$backup; ?>
</div>
<?php
if (!empty($result_min)) {
	$min_woo_price_old = get_post_meta( get_the_ID(), 'rehub_min_woo_price', true );
	$min_woo_price = min($result_min); //Get minimal woo price
	if ( $min_woo_price !='' && $min_woo_price_old !='' && $min_woo_price != $min_woo_price_old ){
		update_post_meta(get_the_ID(), 'rehub_min_woo_price', $min_woo_price); // save minimal price of price range affiliate links
		update_post_meta(get_the_ID(), 'rehub_main_product_price', $min_woo_price); 
	}
	elseif($min_woo_price !='' && $min_woo_price_old =='') {
		update_post_meta(get_the_ID(), 'rehub_min_woo_price', $min_woo_price); 
		update_post_meta(get_the_ID(), 'rehub_main_product_price', $min_woo_price);
	}					 
}
?>
<?php
}
}


/*-----------------------------------------------------------------------------------*/
# 	Exerpt affiliate button generating
/*-----------------------------------------------------------------------------------*/

if( !function_exists('rehub_create_btn') ) {
function rehub_create_btn ($btn_more='', $showme = '') {
	?>

		<?php
			$aff_url_exist = get_post_meta( get_the_ID(), 'affegg_product_orig_url', true );
			$offer_url_exist = get_post_meta( get_the_ID(), 'rehub_offer_product_url', true );

		if (!empty($offer_url_exist)) : ?>

			<?php
				$offer_url = $offer_url_exist;
			 	$offer_price = get_post_meta( get_the_ID(), 'rehub_offer_product_price', true );
			 	$offer_btn_text = get_post_meta( get_the_ID(), 'rehub_offer_btn_text', true );
			 	$offer_price_old = get_post_meta( get_the_ID(), 'rehub_offer_product_price_old', true );
			 	$offer_coupon = get_post_meta( get_the_ID(), 'rehub_offer_product_coupon', true );
			 	$offer_coupon_date = get_post_meta( get_the_ID(), 'rehub_offer_coupon_date', true );
			 	$offer_coupon_mask = get_post_meta( get_the_ID(), 'rehub_offer_coupon_mask', true );
			?>				

			<?php if(!empty($offer_coupon_date)) : ?>
				<?php
					$timestamp1 = strtotime($offer_coupon_date);
					$seconds = $timestamp1 - time();
					$days = floor($seconds / 86400);
					$seconds %= 86400;
            		if ($days > 0) {
            			$coupon_style = '';
            		}
            		elseif ($days == 0){
            			$coupon_style = '';
            		}
            		else {
            			$coupon_text = __('Coupon is Expired', 'rehub_child');
            			$coupon_style = 'expired_coupon';
            		}
				?>
			<?php endif ;?>
	        <div class="priced_block clearfix">
	            <?php if(!empty($offer_price) && $showme !='button') : ?>
	            	<p>
	            		<span class="price_count">
	            			<ins><?php echo esc_html($offer_price) ?></ins>
	            			<?php if($offer_price_old !='') :?> <del><?php echo esc_html($offer_price_old) ; ?></del><?php endif ;?>
	            		</span>
	            	</p>
	            <?php endif ;?>
		    	<?php if(!empty($offer_coupon)) : ?>
		    		<?php if($showme !='price') : ?>
			    		<div class="post_offer_anons">
			    			<?php wp_enqueue_script('zeroclipboard'); ?>
			    			<?php if (empty($offer_coupon_mask)) :?>
			                	<div class="rehub_offer_coupon not_masked_coupon <?php if(!empty($offer_coupon_date)) {echo $coupon_style ;} ?>" data-clipboard-text="<?php echo $offer_coupon ?>"><i class="fa fa-scissors fa-rotate-180"></i><span class="coupon_text"><?php echo $offer_coupon ?></span></div>
			           	 	<?php else :?>
			                	<span class="btn_offer_block rehub_offer_coupon masked_coupon <?php if(!empty($offer_coupon_date)) {echo $coupon_style ;} ?>" data-clipboard-text="<?php echo esc_html ($offer_coupon) ?>" data-codeid="<?php echo get_the_ID()?>" data-dest="<?php echo esc_url($offer_url) ?>">
			                		<?php if($offer_btn_text !='') :?>
				            			<?php echo esc_html ($offer_btn_text) ; ?>
			                		<?php elseif(rehub_option('rehub_mask_text') !='') :?>
			                			<?php echo rehub_option('rehub_mask_text') ; ?>
			                		<?php else :?>
			                			<?php _e('Reveal coupon', 'rehub_child') ?>
			                		<?php endif ;?>
			                	</span>
			            	<?php endif;?>
		            	</div>
	            	<?php endif;?>
		    	<?php else : ?>
		    		<?php if($showme !='price') : ?>
			            <div>
				            <a href="<?php echo esc_url ($offer_url) ?>" class="btn_offer_block" target="_blank" rel="nofollow">
				            <?php if($offer_btn_text !='') :?>
				            	<?php echo esc_html ($offer_btn_text); ?>
				            <?php elseif(rehub_option('rehub_btn_text') !='') :?>
				            	<?php echo rehub_option('rehub_btn_text') ; ?>
				            <?php else :?>
				            	<?php _e('Buy this item', 'rehub_framework') ?>
				            <?php endif ;?>
				            </a>
			            </div>
		            <?php endif;?>
		        <?php endif; ?>
	        </div>

		<?php elseif (!empty($aff_url_exist)) : ?>

			<?php if (version_compare(PHP_VERSION, '5.3.0', '>=')) {
				include(locate_template( 'inc/parts/affeggbutton.php' ) );
			} ?>

		<?php elseif (vp_metabox('rehub_post.rehub_framework_post_type') == 'review' && vp_metabox('rehub_post.review_post.0.review_post_schema_type') == 'review_post_review_product') : ?>
			<?php $review_aff_link = vp_metabox('rehub_post.review_post.0.review_post_product.0.review_aff_link');
			if(function_exists('thirstyInit') && !empty($review_aff_link)) :?>
				<?php
					$linkpost = get_post($review_aff_link);
				 	$offer_price = get_post_meta( $linkpost->ID, 'rehub_aff_price', true );
				 	$offer_btn_text = get_post_meta( $linkpost->ID, 'rehub_aff_btn_text', true );
				 	$offer_url = get_post_permalink($review_aff_link) ;
				 	$offer_price_old = get_post_meta( $linkpost->ID, 'rehub_aff_price_old', true );
				?>
			<?php else :?>
		        <?php $offer_price = vp_metabox('rehub_post.review_post.0.review_post_product.0.review_post_product_price') ?>
		        <?php $offer_url = vp_metabox('rehub_post.review_post.0.review_post_product.0.review_post_product_url') ?>
		        <?php $offer_btn_text = vp_metabox('rehub_post.review_post.0.review_post_product.0.review_post_btn_text') ?>
		        <?php $offer_price_old = vp_metabox('rehub_post.review_post.0.review_post_product.0.review_post_product_price_old') ?>
	    	<?php endif;?>
	        <div class="priced_block clearfix">
	            <?php if(!empty($offer_price) && $showme !='button') : ?><p> <span class="price_count"><ins><?php echo esc_html($offer_price) ?></ins><?php if($offer_price_old !='') :?> <del><?php echo esc_html($offer_price_old) ; ?></del><?php endif ;?></span></p><?php endif ;?>
	            <?php if($showme !='price') : ?><div><a href="<?php echo esc_url ($offer_url) ?>" class="btn_offer_block" target="_blank" rel="nofollow"><?php if($offer_btn_text !='') :?><?php echo $offer_btn_text ; ?><?php elseif(rehub_option('rehub_btn_text') !='') :?><?php echo rehub_option('rehub_btn_text') ; ?><?php else :?><?php _e('Buy this item', 'rehub_framework') ?><?php endif ;?></a></div><?php endif ;?>
	        </div>
	    <?php elseif (vp_metabox('rehub_post.rehub_framework_post_type') == 'review' && vp_metabox('rehub_post.review_post.0.review_post_schema_type') == 'review_aff_product') :?>
			<?php $rehub_aff_post_ids = vp_metabox('rehub_post.review_post.0.review_aff_product.0.review_aff_links');
			if(function_exists('thirstyInit') && !empty($rehub_aff_post_ids)) :?>
		        <div class="priced_block clearfix">
	                <?php $min_aff_price_count = get_post_meta(get_the_ID(), 'rehub_min_aff_price', true); if ($min_aff_price_count !='' && $showme !='button') : ?>
	                	<p><span class="price_count"><?php echo rehub_option('rehub_currency'); echo esc_html($min_aff_price_count); ?></span></p>
	                <?php endif ;?>
		            <?php if($showme !='price') : ?><div><a href="<?php the_permalink();?>#aff-link-list" class="btn_offer_block" target="_blank" rel="nofollow"><?php if(rehub_option('rehub_btn_text_aff_links') !='') :?><?php echo rehub_option('rehub_btn_text_aff_links') ; ?><?php else :?><?php _e('Choose offer', 'rehub_framework') ?><?php endif ;?></a></div><?php endif ;?>
		        </div>
	    	<?php endif ;?>

	    <?php elseif (vp_metabox('rehub_post.rehub_framework_post_type') == 'review' && vp_metabox('rehub_post.review_post.0.review_post_schema_type') == 'review_woo_list') :?>
			<?php $review_woo_list_links = vp_metabox('rehub_post.review_post.0.review_woo_list.0.review_woo_list_links');
			if(in_array( 'woocommerce/woocommerce.php', apply_filters( 'active_plugins', get_option( 'active_plugins' ) ) ) && !empty($review_woo_list_links)) :?>
		        <div class="priced_block clearfix">
	                <?php $min_woo_price_count = get_post_meta(get_the_ID(), 'rehub_min_woo_price', true); if ($min_woo_price_count !='' && $showme !='button') : ?>
	                	<p><span class="price_count"><?php echo rehub_option('rehub_currency'); echo $min_woo_price_count; ?></span></p>
	                <?php endif ;?>
		            <?php if($showme !='price') : ?><div><a href="<?php the_permalink();?>#woo-link-list" class="btn_offer_block"><?php if(rehub_option('rehub_btn_text_aff_links') !='') :?><?php echo rehub_option('rehub_btn_text_aff_links') ; ?><?php else :?><?php _e('Choose offer', 'rehub_framework') ?><?php endif ;?></a></div><?php endif ;?>
		        </div>
	    	<?php endif ;?>

		<?php elseif (vp_metabox('rehub_post.rehub_framework_post_type') == 'review' && vp_metabox('rehub_post.review_post.0.review_post_schema_type') == 'review_woo_product') :?>
        	<?php $review_woo_link = vp_metabox('rehub_post.review_post.0.review_woo_product.0.review_woo_link');?>
        	<?php if(rehub_option('rehub_btn_text') !='') :?><?php $btn_txt = rehub_option('rehub_btn_text') ; ?><?php else :?><?php $btn_txt = __('Buy this item', 'rehub_framework') ;?><?php endif ;?>
        	<?php global $woocommerce; global $post;$backup=$post; if($woocommerce) :?>
				<?php
					$args = array(
						'post_type' 		=> 'product',
						'posts_per_page' 	=> 1,
						'no_found_rows' 	=> 1,
						'post_status' 		=> 'publish',
						'p'					=> $review_woo_link,

					);
				?>
				<?php $products = new WP_Query( $args ); if ( $products->have_posts() ) : ?>
					<?php while ( $products->have_posts() ) : $products->the_post(); global $product?>
					<?php $offer_price = $product->get_price_html() ?>
					<div class="priced_block clearfix">
		                <?php if(!empty($offer_price) && $showme !='button') : ?><p> <span class="price_count"><?php echo $offer_price ?></span></p><?php endif ;?>
		                <?php if($showme !='price') : ?>
			                <div>
			                	<?php if ($product->product_type =='external' && $product->add_to_cart_url() =='') :?>
			                		<a class='btn_offer_block' href="<?php the_permalink();?>" target="_blank"><?php _e('Prices', 'rehub_framework') ;?></a>
			                	<?php else :?>
			                    	<?php if ( $product->is_in_stock() ) : ?>
										<?php
											echo apply_filters( 'woocommerce_loop_add_to_cart_link',
											sprintf( '<a href="%s" rel="nofollow" data-product_id="%s" data-product_sku="%s" class="btn_offer_block %s product_type_%s">%s</a>',
											esc_url( $product->add_to_cart_url() ),
											esc_attr( $product->id ),
											esc_attr( $product->get_sku() ),
											$product->is_purchasable() && $product->is_in_stock() ? 'add_to_cart_button' : '',
											esc_attr( $product->product_type ),
											esc_html( $btn_txt )
											), $product );
										?>
	    							<?php endif; ?>
								<?php endif; ?>
			                </div>
		                <?php endif; ?>
		            </div>
				<?php endwhile; endif;  wp_reset_postdata(); $post=$backup; ?>
        	<?php endif ;?>

        <?php else :?>

        	<?php if ($btn_more =='yes') :?>

	        	<?php if (vp_metabox('rehub_post_side.read_more_custom')): ?>
			  		<a href="<?php the_permalink();?>" class="btn_more btn_more_custom"><?php echo strip_tags(vp_metabox('rehub_post_side.read_more_custom'));?></a>
				<?php elseif (rehub_option('rehub_readmore_text') !=''): ?>
			  		<a href="<?php the_permalink();?>" class="btn_more"><?php echo strip_tags(rehub_option('rehub_readmore_text'));?></a>
			  	<?php else: ?>
					<a href="<?php the_permalink();?>" class="btn_more"><?php _e('READ MORE  +', 'rehub_framework') ;?></a>
			  	<?php endif ?>

        	<?php endif ;?>

	    <?php endif ;?>

	<?php
}
}

if( !function_exists('rehub_create_affiliate_link') ) {
function rehub_create_affiliate_link () {
$aff_url_exist = get_post_meta( get_the_ID(), 'affegg_product_orig_url', true );
$offer_url_exist = get_post_meta( get_the_ID(), 'rehub_offer_product_url', true );
if(!empty($offer_url_exist) ) :
	$out = esc_url($offer_url_exist);
elseif(!empty($aff_url_exist)) :
	if (version_compare(PHP_VERSION, '5.3.0', '>=')) :
		include(locate_template( 'inc/parts/affeggurl.php' ) );
	endif; 
elseif (vp_metabox('rehub_post.rehub_framework_post_type') == 'review' && vp_metabox('rehub_post.review_post.0.review_post_schema_type') == 'review_post_review_product') :
	$review_aff_link = vp_metabox('rehub_post.review_post.0.review_post_product.0.review_aff_link');
	if(function_exists('thirstyInit') && !empty($review_aff_link)) :
		$offer_url = get_post_permalink($review_aff_link);
	else :
        $offer_url = vp_metabox('rehub_post.review_post.0.review_post_product.0.review_post_product_url');
	endif;
    $out = $offer_url;
elseif (vp_metabox('rehub_post.rehub_framework_post_type') == 'review' && vp_metabox('rehub_post.review_post.0.review_post_schema_type') == 'review_aff_product') :
	$out = get_the_permalink().'#aff-link-list';
elseif (vp_metabox('rehub_post.rehub_framework_post_type') == 'review' && vp_metabox('rehub_post.review_post.0.review_post_schema_type') == 'review_woo_list') :
	$out = get_the_permalink().'#woo-link-list';
elseif (vp_metabox('rehub_post.rehub_framework_post_type') == 'review' && vp_metabox('rehub_post.review_post.0.review_post_schema_type') == 'review_woo_product') :
	$review_woo_link = vp_metabox('rehub_post.review_post.0.review_woo_product.0.review_woo_link');
	global $woocommerce; global $post;$backup=$post; if($woocommerce) :
		$args = array(
			'post_type' 		=> 'product',
			'posts_per_page' 	=> 1,
			'no_found_rows' 	=> 1,
			'post_status' 		=> 'publish',
			'p'					=> $review_woo_link,

		);
		$products = new WP_Query( $args );
		if ( $products->have_posts() ) :
		while ( $products->have_posts() ) : $products->the_post(); global $product;
        	if ($product->product_type =='external' && $product->add_to_cart_url() =='') :
        		$out = get_the_permalink();
        	else :
            	$out = esc_url( $product->add_to_cart_url() );
			endif;
		endwhile; endif; wp_reset_postdata(); $post=$backup;
	endif;
elseif (vp_metabox('rehub_post.rehub_framework_post_type') == 'link' && vp_metabox('rehub_post.link_post.0.link_post_url') != '') :
	$offer_url = vp_metabox('rehub_post.link_post.0.link_post_url');
	$out = $offer_url;
else :
	$out = get_the_permalink();
endif;
return $out;
}
}


/*-----------------------------------------------------------------------------------*/
# 	Quick offer function
/*-----------------------------------------------------------------------------------*/

if( !function_exists('rehub_quick_offer') ) {
function rehub_quick_offer(){
	global $post;
	?>
	<?php
		$offer_url = get_post_meta( $post->ID, 'rehub_offer_product_url', true );
		$offer_price = get_post_meta( $post->ID, 'rehub_offer_product_price', true );
		$offer_title = get_post_meta( $post->ID, 'rehub_offer_name', true );
		$offer_thumb = get_post_meta( $post->ID, 'rehub_offer_product_thumb', true );
		$offer_btn_text = get_post_meta( $post->ID, 'rehub_offer_btn_text', true );
		$offer_price_old = get_post_meta( $post->ID, 'rehub_offer_product_price_old', true );
		$offer_coupon = get_post_meta( $post->ID, 'rehub_offer_product_coupon', true );
		$offer_coupon_date = get_post_meta( $post->ID, 'rehub_offer_coupon_date', true );
		$offer_coupon_mask = get_post_meta( $post->ID, 'rehub_offer_coupon_mask', true );
		$offer_desc = get_post_meta( $post->ID, 'rehub_offer_product_desc', true );
		$offer_brand_url = esc_url (get_post_meta( $post->ID, 'rehub_offer_logo_url', true ));
	?>
	<?php $coupon_style = ''; if(!empty($offer_coupon_date)) : ?>
		<?php
			$timestamp1 = strtotime($offer_coupon_date);
			$seconds = $timestamp1 - time();
			$days = floor($seconds / 86400);
			$seconds %= 86400;
    		if ($days > 0) {
    			$coupon_text = $days.' '.__('days left', 'rehub_framework');
    			$coupon_style = '';
    		}
    		elseif ($days == 0){
    			$coupon_text = __('Last day', 'rehub_framework');
    			$coupon_style = '';
    		}
    		else {
    			$coupon_text = __('Coupon is Expired', 'rehub_framework');
    			$coupon_style = 'expired_coupon';
    		}
		?>
	<?php endif ;?>	
	<?php $coupon_enabled_style = (!empty($offer_coupon_mask)) ? ' reveal_enabled '.$coupon_style.'' : ' '.$coupon_style.''; ?>
	<div class="rehub_feat_block table_view_block<?php echo $coupon_enabled_style ;?>"><a name="quick-offer"></a>
		<div class="block_with_coupon">
	            <div class="offer_thumb">
	            <a href="<?php echo $offer_url ?>" target="_blank" rel="nofollow">
	            	<?php if (!empty($offer_thumb) ) :?>
	            		<img src="<?php $params = array( 'width' => 120, 'height' => 90 ); echo bfi_thumb( $offer_thumb, $params ); ?>" alt="<?php the_title_attribute(); ?>" />
	            	<?php else :?>
	            		<?php wpsm_thumb ('med_thumbs') ?>
	            	<?php endif ;?>
	            </a>
	            </div>
	   		<div class="desc_col">
	            <div class="offer_title"><?php echo esc_html($offer_title) ;?></div>
	            <p><?php echo wp_kses_post($offer_desc);  ?></p>
	        </div>
	        <?php if(!empty($offer_price)) : ?>
	        	<div class="price_col">
	        		<p><span class="price_count"><ins><?php echo esc_html($offer_price) ?></ins><?php if($offer_price_old !='') :?> <del><?php echo esc_html($offer_price_old) ; ?></del><?php endif ;?></span></p>
	        		<?php if (!empty($offer_brand_url)) :?>
		        		<div class="brand_logo_small">	            
			            	<img src="<?php $params = array( 'width' => 50 ); echo bfi_thumb( $offer_brand_url, $params ); ?>" alt="<?php the_title_attribute(); ?>" />		            
					    </div>
				    <?php endif; ?>
	        	</div>
	        <?php endif ;?>
	        <div class="buttons_col">
	            <div class="priced_block clearfix">
	                <div>
	                	<a href="<?php echo esc_url ($offer_url) ?>" class="btn_offer_block" target="_blank" rel="nofollow">
	                		<?php if($offer_btn_text !='') :?>
	                			<?php echo $offer_btn_text ; ?>
	                		<?php elseif(rehub_option('rehub_btn_text') !='') :?>
	                			<?php echo rehub_option('rehub_btn_text') ; ?>
	                		<?php else :?>
	                			<?php _e('Buy this item', 'rehub_framework') ?>
	                		<?php endif ;?>
	                	</a>
	                </div>
					<?php if(!empty($offer_coupon)) : ?>
						<?php wp_enqueue_script('zeroclipboard'); ?>
						<?php if (empty($offer_coupon_mask)) :?>
                            <div class="rehub_offer_coupon not_masked_coupon <?php if(!empty($offer_coupon_date)) {echo $coupon_style ;} ?>" data-clipboard-text="<?php echo $offer_coupon ?>"><i class="fa fa-scissors fa-rotate-180"></i><span class="coupon_text"><?php echo $offer_coupon ?></span></div>
                        <?php else :?>
                            <div class="rehub_offer_coupon masked_coupon <?php if(!empty($offer_coupon_date)) {echo $coupon_style ;} ?>" data-clipboard-text="<?php echo $offer_coupon ?>" data-codeid="<?php echo $post->ID?>" data-dest="<?php echo esc_url($offer_url) ?>"><?php if(rehub_option('rehub_mask_text') !='') :?><?php echo rehub_option('rehub_mask_text') ; ?><?php else :?><?php _e('Reveal coupon', 'rehub_framework') ?><?php endif ;?><i class="fa fa-external-link-square"></i></div>
                        <?php endif;?>
                    	<?php if(!empty($offer_coupon_date)) {echo '<div class="time_offer">'.$coupon_text.'</div>';} ?>
					<?php endif ;?>
	            </div>
	        </div>
    	</div>
	</div>
	<?php //save clean price to post meta
		$offer_price_clean = rehub_price_clean($offer_price); 
		$offer_price_clean_old = get_post_meta( $post->ID, 'rehub_main_product_price', true );
		if ( $offer_price_clean !='' && $offer_price_clean_old !='' && $offer_price_clean != $offer_price_clean_old ){
			update_post_meta(get_the_ID(), 'rehub_main_product_price', $offer_price_clean); 
		}
		elseif($offer_price_clean !='' && $offer_price_clean_old =='') {
			update_post_meta(get_the_ID(), 'rehub_main_product_price', $offer_price_clean); 
		}
	 ?>	
	<?php
}
}


/*-----------------------------------------------------------------------------------*/
# 	Ajax coupon
/*-----------------------------------------------------------------------------------*/

if( !function_exists('coupon_get_code') ) {
function coupon_get_code(){
	if ( 'GET' != $_SERVER['REQUEST_METHOD'] ) {
		$response = __( 'Sorry, only get method allowed', 'rehub_framework' );
		echo  $response;
		die;
	}
	$codeid = $_GET['codeid'];
	$code = get_post( $codeid );
	if( !empty( $code ) ){
		if ('thirstylink' == get_post_type($code->ID)) {$offer_coupon = get_post_meta( $code->ID, 'rehub_aff_coupon', true ); $offer_link = get_the_permalink($code->ID);}
		elseif ('post' == get_post_type($codeid)) {$offer_coupon = get_post_meta( $codeid, 'rehub_offer_product_coupon', true ); $offer_link = get_post_meta( $codeid, 'rehub_offer_product_url', true );}
		else {
			$offer_coupon = get_post_meta( $code->ID, 'rehub_woo_coupon_code', true );
			$args = array(
				'post_type' 		=> 'product',
				'posts_per_page' 	=> 1,
				'no_found_rows' 	=> 1,
				'post_status' 		=> 'publish',
				'p'					=> $codeid,

			);
			$products = new WP_Query( $args );
			if ( $products->have_posts() ) : while ( $products->have_posts() ) : $products->the_post();
			global $product;
			$offer_link = esc_url( $product->add_to_cart_url() );
			endwhile; endif;  wp_reset_postdata();

		}
		$response = '<div class="coupon_code_in_modal"><div class="re_title_inmodal">'.__('Here is your coupon code', 'rehub_framework').'</div>';
		$response .= '<div class="text_copied_coupon">'.__('Code is copied', 'rehub_framework').'</div>';
		$response .= '<div class="coupon_modal_coupon">'.$offer_coupon.'</div>';
		$response .= '<div class="add_modal_coupon">'.__('Go to', 'rehub_framework').' <a href="'.$offer_link.'" target="_blank" rel="nofollow">'.__('Website', 'rehub_framework').'</a> '.__('and use this Offer.', 'rehub_framework').'<br />'.__('Or check your new window for opened website', 'rehub_framework').'</div></div>';
	}
	else{
		$response = __( 'Offer does not exists', 'rehub_framework' );
	}

	echo  $response ;
die();
}
}
add_action('wp_ajax_ajax_code', 'coupon_get_code');
add_action('wp_ajax_nopriv_ajax_code', 'coupon_get_code');

/*-----------------------------------------------------------------------------------*/
# 	Hook offer after content
/*-----------------------------------------------------------------------------------*/

if( !function_exists('set_content_end') ) {
function set_content_end($content) {
	global $post;

	if( is_feed() ) return $content;

	$output = '';
		ob_start();
		wp_link_pages(array( 'before' => '<div class="page-link"><span class="page-link-title">' . __( 'Pages:', 'rehub_child' ).'</span>', 'after' => '</div>', 'pagelink' => '<span>%</span>' ));
		$output .= ob_get_clean();

	$offer_url_exist = get_post_meta( $post->ID, 'rehub_offer_product_url', true );
	if (!empty($offer_url_exist)) :
		$offer_shortcode = get_post_meta( $post->ID, 'rehub_offer_shortcode', true );
		if (empty($offer_shortcode)) :
			ob_start();
			rehub_quick_offer();
			$output .= ob_get_clean();
		endif;
	elseif(vp_metabox('rehub_post.rehub_framework_post_type') == 'review') :
		if(vp_metabox('rehub_post.review_post.0.review_post_product.0.review_post_offer_shortcode') != '1' && vp_metabox('rehub_post.review_post.0.review_post_schema_type') == 'review_post_review_product') :
			ob_start();
			rehub_get_offer();
			$output .= ob_get_clean();
		endif;
		if(vp_metabox('rehub_post.review_post.0.review_aff_product.0.review_aff_offer_shortcode') != '1' && vp_metabox('rehub_post.review_post.0.review_post_schema_type') == 'review_aff_product') :
			ob_start();
			rehub_get_aff_offer();
			$output .= ob_get_clean();
		endif;
		if(vp_metabox('rehub_post.review_post.0.review_woo_product.0.review_woo_offer_shortcode') != '1' && vp_metabox('rehub_post.review_post.0.review_post_schema_type') == 'review_woo_product') :
			$review_woo_link = vp_metabox('rehub_post.review_post.0.review_woo_product.0.review_woo_link');
			ob_start();
			rehub_get_woo_offer($review_woo_link);
			$output .= ob_get_clean();
		endif;
		if(vp_metabox('rehub_post.review_post.0.review_woo_list.0.review_woo_list_shortcode') != '1' && vp_metabox('rehub_post.review_post.0.review_post_schema_type') == 'review_woo_list') :
			$review_woo_list_links = vp_metabox('rehub_post.review_post.0.review_woo_list.0.review_woo_list_links');
			if (is_array($review_woo_list_links)) { $review_woo_list_links = implode(',', $review_woo_list_links); }
			ob_start();
			rehub_get_woo_list($data_source = 'ids', $type ='', $cat = '', $tag = '', $ids = $review_woo_list_links);
			$output .= ob_get_clean();
		endif;
	endif;

	if(vp_metabox('rehub_post.rehub_framework_post_type') == 'review' && vp_metabox('rehub_post.review_post.0.review_post_product_shortcode') == '0') :
		ob_start();
		rehub_get_review();
		$output .= ob_get_clean();
	endif;

	return $content.$output;
}
}
add_filter ('the_content', 'set_content_end');

//COMMENT SORT FUNCTIONS
add_action('wp_ajax_nopriv_show_tab', 'show_tab_ajax');
add_action('wp_ajax_show_tab', 'show_tab_ajax');
function show_tab_ajax() {
  	if (!isset($_POST['rating_tabs_id']) || !wp_verify_nonce($_POST['rating_tabs_id'], 'rating_tabs_nonce'))
    die(sha1(microtime())); // return some random trash :)

  	if (!isset($_POST['post_id']) || !isset($_POST['tab_number']))
    	die(sha1(microtime())); // return some random trash :)

  	$post_id = (int)$_POST['post_id'];
  	$tab_number = (int)$_POST['tab_number'];
  	if (empty($post_id) || empty($tab_number) || $post_id<1 || $tab_number<1 || $tab_number>4)
    	die(sha1(microtime())); // return some random trash :)

  	$comments_count = wp_count_comments($post_id);
  	if (empty($comments_count->approved))
    	die('No comments on this post');
  	unset($comments_count);

	$comments_v = get_comments(array(
		'post_id' => $post_id,
		'status'  => 'approve',
		'orderby' => 'comment_date',
		'order'   => 'DESC',
	));

  	foreach($comments_v as $key=>$comment) {
    	$meta = get_comment_meta($comment->comment_ID);
    	$comment->user_average = isset($meta['user_average'][0]) ? $meta['user_average'][0] : 0;
    	$comment->recomm_plus  = isset($meta['recomm_plus'][0]) ? $meta['recomm_plus'][0] : 0;
    	$comment->recomm_minus = isset($meta['recomm_minus'][0]) ? $meta['recomm_minus'][0] : 0;
    	$comments_and_meta_v[$key] = $comment;
  	}
  	unset($comments_v);

  	switch ($tab_number) {
    	case 1 : $sorted_comments_v = show_tab_get_newest($comments_and_meta_v); break;
    	case 2 : $sorted_comments_v = show_tab_get_most_helpful($comments_and_meta_v); break;
    	case 3 : $sorted_comments_v = show_tab_get_highest_rating($comments_and_meta_v); break;
    	case 4 : $sorted_comments_v = show_tab_get_lowest_rating($comments_and_meta_v); break;
    default: die(sha1(microtime())); // not needed, but...
  	}
  	unset($comments_and_meta_v);

  	show_tab_print_comments($sorted_comments_v);
  	exit;
}
// ----------------------------------------------
function show_tab_get_newest($comments_v) {
  	return $comments_v; // it already sorted as we need
}
// ----------------------------------------------
function show_tab_get_most_helpful_sort ($a, $b) {
    if ($a->recomm_plus > $b->recomm_plus)
      	return -1;
    elseif ($a->recomm_plus < $b->recomm_plus)
      	return 1;
    elseif ($a->comment_ID > $b->comment_ID)
      	return -1;
    else
      	return 1;
}
function show_tab_get_most_helpful($comments_v) {
  	$comments_v = show_tab_delete_unlikes_comments($comments_v);
  	usort($comments_v, 'show_tab_get_most_helpful_sort');
  	return $comments_v;
}
// ----------------------------------------------
function show_tab_get_highest_rating_sort ($a, $b) {
    if ($a->user_average > $b->user_average)
      	return -1;
    elseif ($a->user_average < $b->user_average)
      	return 1;
    elseif ($a->comment_ID > $b->comment_ID)
      	return -1;
    else
      return 1;
}
function show_tab_get_highest_rating($comments_v) {
  	$comments_v = show_tab_delete_unrated_comments($comments_v);
  	usort($comments_v, 'show_tab_get_highest_rating_sort');
  	return $comments_v;
}
// ----------------------------------------------

function show_tab_get_lowest_rating_sort ($a, $b) {
   if ($a->user_average > $b->user_average)
      	return 1;
    elseif ($a->user_average < $b->user_average)
      	return -1;
    elseif ($a->comment_ID > $b->comment_ID)
      	return 1;
    else
      	return -1;
}
function show_tab_get_lowest_rating($comments_v) {
  	$comments_v = show_tab_delete_unrated_comments($comments_v);
  	usort($comments_v, 'show_tab_get_lowest_rating_sort');
  	return $comments_v;
}
// ----------------------------------------------
function show_tab_delete_unrated_comments($comments_v) {
  	$result_v = array();
  	foreach($comments_v as $comment) {
    if (empty($comment->user_average)) continue;
    	$result_v[] = $comment;
  	}
  	return $result_v;
}
// ----------------------------------------------
function show_tab_delete_unlikes_comments($comments_v) {
  	$result_v = array();
  	foreach($comments_v as $comment) {
    	if (empty($comment->recomm_plus)) continue;
    	$result_v[] = $comment;
  	}
  	return $result_v;
}
// ----------------------------------------------
function show_tab_print_comments($sorted_comments_v) {
  	wp_list_comments(array(
    	'avatar_size'   => 50,
    	'max_depth'     => 4,
    	'style'         => 'ul',
    	'reverse_top_level' => 0,
    	'callback'      => 'rehub_framework_comments',
    	'echo'          => 'true'
  	), $sorted_comments_v);
}


//Unset some templates for Content Egg
if (!function_exists('rehub_amazon_filters')) {

    function rehub_amazon_filters($templates, $module) {
        if ($module == 'Amazon') {
            //unset ($templates['data_grid']);
            //unset ($templates['data_list']);
            //unset ($templates['data_item']);
            
        }
        if ($module == 'Youtube') {
            unset ($templates['data_responsive_embed']);
            unset ($templates['data_simple']);       
        } 
        if ($module == 'GoogleNews') {
            unset ($templates['data_simple']);       
        } 
        if ($module == 'GoogleImages') {
            unset ($templates['data_simple']);       
        }           
        if ($module == 'GoogleBooks') {
            unset ($templates['data_simple']);       
        } 
        if ($module == 'Twitter') {
            unset ($templates['data_simple']);       
        }  
        if ($module == 'Flickr') {
            unset ($templates['data_simple']);       
        }                                 
        return $templates;

    }
}
add_filter('content_egg_module_templates', 'rehub_amazon_filters', 13, 2);

function rehub_sort_price_ce ($a, $b) {
	if (!$a['price']) return 1;
	if (!$b['price']) return -1;
	return $a['price'] - $b['price'];
}

//Save data from CE
if (!function_exists('rehub_save_meta_ce')) {
    function rehub_save_meta_ce() {
    	global $post;
    	$decimal_point = __('number_format_decimal_point', 'content-egg-tpl');
    	$thousands_sep = __('number_format_thousands_sep', 'content-egg-tpl');     
        if ($decimal_point == 'number_format_decimal_point')
            $decimal_point = '.';
        if ($thousands_sep == 'number_format_thousands_sep')
            $thousands_sep = ',';  
        $cegg_field_array = rehub_option('save_meta_for_ce');
        $cegg_fields = array();
        if (!empty($cegg_field_array) && is_array($cegg_field_array)) {
        	foreach ($cegg_field_array as $cegg_field) {
        		$cegg_field_value = get_post_meta ($post->ID, '_cegg_data_'.$cegg_field.'', true);
        		if (!empty ($cegg_field_value) && is_array($cegg_field_value)) {
        			$cegg_fields += $cegg_field_value;
        		}		
        	}
        	usort($cegg_fields, 'rehub_sort_price_ce');
        }
    	if (!empty($cegg_field_array) && is_array($cegg_field_array)) {
    		$url_field = get_post_meta ($post->ID, 'rehub_offer_product_url', true);
    		if (!empty($cegg_fields) && is_array($cegg_fields)) {
				$price_sale = $price_old = '';        							
	    		if(!empty ($cegg_fields[0]['price'])) { //Saving price with price pattern
					if (rehub_option('price_pattern') == 'us' || rehub_option('price_pattern') == 'in') {
						$price_sale = $cegg_fields[0]['currency'].number_format($cegg_fields[0]['price'], 2, $decimal_point, $thousands_sep);								
					}
					elseif (rehub_option('price_pattern') == 'eu') {
						$price_sale = number_format($cegg_fields[0]['price'], 2, $decimal_point, $thousands_sep).$cegg_fields[0]['currency'];			
					}
					else {
						$price_sale = $cegg_fields[0]['currency'].number_format($cegg_fields[0]['price'], 2, $decimal_point, $thousands_sep);
					}	    			
	    			
	    		}	
	    		if(!empty ($cegg_fields[0]['priceOld'])) {
					if (rehub_option('price_pattern') == 'us' || rehub_option('price_pattern') == 'in') {
						$price_old = $cegg_fields[0]['currency'].number_format($cegg_fields[0]['priceOld'], 2, $decimal_point, $thousands_sep);								
					}
					elseif (rehub_option('price_pattern') == 'eu') {
						$price_old = number_format($cegg_fields[0]['priceOld'], 2, $decimal_point, $thousands_sep).$cegg_fields[0]['currency'];			
					}
					else {
						$price_old = $cegg_fields[0]['currency'].number_format($cegg_fields[0]['priceOld'], 2, $decimal_point, $thousands_sep);
					}	    						
	    		}
				if ('product' == get_post_type($post->ID)) {
					if(!empty ($cegg_fields[0]['price'])) {
						update_post_meta($post->ID, '_sale_price', $cegg_fields[0]['price']);
					}
					if(!empty ($cegg_fields[0]['priceOld'])) {
						update_post_meta($post->ID, '_regular_price', $cegg_fields[0]['priceOld']);
					}
					update_post_meta($post->ID, '_product_url', $cegg_fields[0]['url']);									
				}	
				else {   		
		    		update_post_meta($post->ID, 'rehub_main_product_price', $cegg_fields[0]['price']);
			    	update_post_meta($post->ID, 'rehub_offer_product_price', $price_sale);
		    		update_post_meta($post->ID, 'rehub_offer_product_price_old', $price_old);		    					 
		    		update_post_meta($post->ID, 'rehub_offer_product_url', $cegg_fields[0]['url']);
		    		update_post_meta($post->ID, 'rehub_offer_shortcode', '1');	 
		    		if(!empty ($cegg_fields[0]['title'])) {
		    			update_post_meta($post->ID, 'rehub_offer_name', esc_html($cegg_fields[0]['title'])); 
		    		}	    		
		    		if(!empty ($cegg_fields[0]['description'])) {
		    			update_post_meta($post->ID, 'rehub_offer_product_desc', esc_html($cegg_fields[0]['description'])); 
		    		}
		    		if(!empty ($cegg_fields[0]['img'])) {
		    			update_post_meta($post->ID, 'rehub_offer_product_thumb', $cegg_fields[0]['img']); 
		    		}
	    		}
    		}
    		if (rehub_option('delete_meta_for_ce') == '1' && !empty($url_field) && empty($cegg_fields)) {
    			delete_post_meta($post->ID, 'rehub_offer_product_price'); 
    			delete_post_meta($post->ID, 'rehub_offer_product_price_old');
    			delete_post_meta($post->ID, 'rehub_offer_shortcode');
    			delete_post_meta($post->ID, 'rehub_offer_product_url');  
    			delete_post_meta($post->ID, 'rehub_main_product_price');
    			delete_post_meta($post->ID, 'rehub_offer_name');
    			delete_post_meta($post->ID, 'rehub_offer_product_desc');
    			delete_post_meta($post->ID, 'rehub_offer_product_thumb');    			  			    			
    		}

    	}
    }
}
add_action('content_egg_save_data', 'rehub_save_meta_ce', 13);
?>