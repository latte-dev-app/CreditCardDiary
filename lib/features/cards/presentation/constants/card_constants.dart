/// クレジットカード関連の定数
class CardConstants {
  // 主要なクレジットカード名
  static const List<String> cardNames = [
    '楽天カード',
    'PayPayカード',
    '三井住友カード',
    'JALカード',
    'UCSカード',
    'その他',
  ];

  // カード種類
  static const List<String> cardTypes = [
    'Visa',
    'Mastercard',
    'American Express',
    'JCB',
    'Diners Club',
    'Discover',
    'その他',
  ];

  // デフォルトのカード色
  static const String defaultCardColor = '#FF6B6B';

  // デフォルトのカード種類
  static const String defaultCardType = 'Visa';

  // カテゴリ別カラーパレット
  static const Map<String, List<String>> colorPalettes = {
    '基本色': [
      '#FF6B6B',
      '#4ECDC4',
      '#95E1D3',
      '#F38181',
      '#AA96DA',
      '#FCBAD3',
    ],
    '金融系': [
      '#003366',
      '#004C99',
      '#0066CC',
      '#1E88E5',
      '#42A5F5',
      '#64B5F6',
    ],
    '暖色系': [
      '#FF5722',
      '#FF9800',
      '#FFC107',
      '#FFEB3B',
      '#FF6B9D',
      '#E91E63',
    ],
    '寒色系': [
      '#2196F3',
      '#03A9F4',
      '#00BCD4',
      '#009688',
      '#4CAF50',
      '#8BC34A',
    ],
    '落ち着いた色': [
      '#5D4037',
      '#6D4C41',
      '#795548',
      '#8D6E63',
      '#A1887F',
      '#BCAAA4',
    ],
    '鮮やかな色': [
      '#E91E63',
      '#9C27B0',
      '#673AB7',
      '#3F51B5',
      '#00BCD4',
      '#4CAF50',
    ],
  };
}

