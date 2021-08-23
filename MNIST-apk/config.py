import tensorflow as tf


class CFG:
    dataset = "mnist"
    batch_size = 32
    options = tf.data.experimental.AUTOTUNE
    model_path = "model/"