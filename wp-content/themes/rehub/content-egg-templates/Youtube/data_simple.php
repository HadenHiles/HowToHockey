<?php
/*
  Name: Responsive simple
 */
?>
<?php foreach ($items as $item): ?>
    <div class="video-container">
        <iframe width="703" height="395" src="https://www.youtube.com/embed/<?php echo $item['extra']['guid']; ?>" frameborder="0" allowfullscreen></iframe>           
    </div>
<?php endforeach; ?>