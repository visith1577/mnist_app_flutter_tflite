import os
import math
import tensorflow as tf
import tensorflow_datasets as tfds
from config import CFG
import tensorflow_addons as tfa
from tensorflow.keras import layers
from tensorflow import keras

os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"

(ds_train, ds_test), ds_info = tfds.load(
    CFG.dataset,
    split=["train", "test"],
    shuffle_files=False,
    as_supervised=True,
    with_info=True,
)


@tf.function
def normalize_images(img, label):
    return tf.cast(img, tf.float32) / 255., label


@tf.function
def rotate(image, max_degrees=25):
    degrees = tf.random.uniform([], -max_degrees, max_degrees, dtype=tf.float32)
    image = tfa.image.rotate(image, degrees * math.pi / 180, interpolation="BILINEAR")
    return image


@tf.function
def augment(image, label):
    image = tf.image.resize(image, size=[28, 28])

    image = rotate(image)
    image = tf.image.random_contrast(image, lower=0.5, upper=1.5)
    image = tf.image.random_brightness(image, max_delta=0.5)

    return image, label


ds_train = ds_train.cache()
# ds_train = ds_train.with_options(CFG.options)
ds_train = ds_train.shuffle(ds_info.splits["train"].num_examples)
ds_train = ds_train.map(normalize_images, num_parallel_calls=CFG.options)
ds_train = ds_train.map(augment, num_parallel_calls=CFG.options)
ds_train = ds_train.batch(CFG.batch_size)
ds_train = ds_train.prefetch(CFG.options)


# Setup for test Dataset
ds_test = ds_test.map(normalize_images, num_parallel_calls=CFG.options)
ds_test = ds_test.batch(CFG.batch_size)
ds_test = ds_test.prefetch(CFG.options)

def model():
    inputs = keras.Input(shape=(28, 28, 1))
    conv1 = layers.Conv2D(filters=32, kernel_size=5, strides=1, activation='relu')(inputs)
    bn1 = layers.BatchNormalization()(conv1)
    mp1 = layers.MaxPooling2D(pool_size=2, strides=2)(bn1)
    conv2 = layers.Conv2D(filters=64, kernel_size=3, activation='relu')(mp1)
    bn2 = layers.BatchNormalization()(conv2)
    mp2 = layers.MaxPooling2D(pool_size=2, strides=2)(bn2)
    drop = layers.Dropout(0.25)(mp2)
    flat = layers.Flatten()(drop)
    dense = layers.Dense(units=256, use_bias=False)(flat)
    bn3 = layers.BatchNormalization()(dense)
    act1 = layers.ReLU()(bn3)
    dense2 = layers.Dense(units=128, use_bias=False)(act1)
    bn4 = layers.BatchNormalization()(dense2)
    act2 = layers.ReLU()(bn4)
    dense3 = layers.Dense(units=64, use_bias=False)(act2)
    bn5 = layers.BatchNormalization()(dense3)
    act3 = layers.ReLU()(bn5)
    output = layers.Dense(10, activation='softmax')(act3)

    return keras.Model(inputs=inputs, outputs=output)

model = model()
model.compile(
    loss=keras.losses.SparseCategoricalCrossentropy(from_logits=False),
    optimizer=keras.optimizers.Adam(lr=1e-4),
    metrics=['accuracy']

)

model.fit(ds_train, epochs=30, verbose=2)
model.evaluate(ds_test)
model.save("model")
