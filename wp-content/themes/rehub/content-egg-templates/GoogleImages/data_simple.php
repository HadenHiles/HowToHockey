<?php
/*
  Name: Image with description
 */

?>

<?php foreach ($items as $item): ?>
    <div class="text-center"><img src="<?php echo $item['img']; ?>" alt="<?php echo esc_attr($item['keyword']); ?>" class="img-thumbnail-block" /></div>
    <div class="img-descr text-center mb10">
    <p class="font80 mb10"><?php printf(__('Source: %s', 'content-egg'), esc_attr($item['extra']['source'])); ?></p>
    <h4><?php echo esc_html($item['title']); ?></h4>
    <p><?php echo $item['description']; ?></p>
    <div class="clearfix"></div>   
    </div>    
<?php endforeach; ?>