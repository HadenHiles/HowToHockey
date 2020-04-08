<?php
/*
  Name: Simple
 */
?>

<div class="egg-wrap">
    <?php foreach ($items as $item): ?>
        <div class="media">
            <?php if ($item['img']): ?>
                <div class="media-left">
                    <img style="max-width: 225px;" class="media-object thumbnail" src="<?php echo $item['img']; ?>" alt="<?php echo esc_attr($item['title']); ?>" />
                </div>
            <?php endif; ?>
            <div class="media-body">
                <h4 class="media-heading">
                    <a target="_blank" rel="nofollow" href="<?php echo $item['url']; ?>"><?php echo esc_html($item['title']); ?></a>
                </h4>
                <small class="text-meta">
                    <?php echo date(get_option('date_format'), $item['extra']['date']); ?> -
                    <a target="_blank" rel="nofollow" href="<?php echo $item['url']; ?>"><?php echo esc_html($item['extra']['source']); ?></a>
                </small>
                <p><?php echo $item['description']; ?></p>
            </div>
        </div>
    <?php endforeach; ?>
</div>