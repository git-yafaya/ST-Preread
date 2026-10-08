/// 示例书的正文。全部为本项目原创的演示文字，原文为英文、译文为中文。
///
/// 三章刻意覆盖界面需要应对的各种数据形态：
/// - 第一章：两面都有语音；含带说明的插图、超过一屏的长段落、
///   同一面里有语音与无语音的句子混排、某一面没有句级切分的段落。
/// - 第二章：只有原文有语音（朗读面需要回退）；含只有原文、只有译文的段落，
///   以及没有说明的插图。
/// - 第三章：两面都没有语音（本章不可播放）。
library;

import 'sample_content_spec.dart';

const String sampleBookTitle = '雾港来信';
const String sampleBookAuthor = '示例作者';

final List<SampleChapterSpec> sampleChapterSpecs = [
  _lateLetterChapter,
  _keeperLedgerChapter,
  _autumnTideChapter,
];

final SampleChapterSpec _lateLetterChapter = SampleChapterSpec(
  title: '第一章 迟到的信',
  blocks: [
    SampleParagraphSpec(
      source: SampleSideSpec.withAudio([
        'The ferry reached Fog Harbor an hour late.',
        'Lin Wan stepped onto the pier with one suitcase and a letter she '
            'had read too many times.',
        'Nobody was waiting for her.',
      ]),
      translation: SampleSideSpec.withAudio([
        '渡船晚了一个钟头才靠上雾港。',
        '林晚提着一只箱子走上栈桥，口袋里揣着那封读过太多遍的信。',
        '没有人来接她。',
      ]),
    ),
    const SampleIllustrationSpec(
      imageFileName: 'fog_harbor_pier.png',
      caption: '雾中的栈桥',
    ),
    SampleParagraphSpec(
      source: const SampleSideSpec([
        SampleSentence('The letter was signed by an uncle she had never met.'),
        SampleSentence(
          '“Come before the autumn tide,” it said.',
          hasAudio: false,
        ),
        SampleSentence(
          '“The lighthouse needs a keeper, and I am running out of mornings.”',
        ),
      ]),
      translation: SampleSideSpec.withAudio([
        '信的落款是一位她从未见过的叔父。',
        '“赶在秋潮之前来，”信上写道。',
        '“灯塔需要一个守灯人，而我剩下的清晨不多了。”',
      ]),
    ),
    _cliffRoadParagraph,
    SampleParagraphSpec(
      source: SampleSideSpec.withoutSentenceData([
        'The footsteps stopped behind the blue door.',
        'Lin Wan straightened her collar and waited.',
      ]),
      translation: SampleSideSpec.withAudio(['脚步声在蓝色的门后停住了。', '林晚理了理衣领，等着。']),
    ),
  ],
);

/// 超过一屏的长段落，用来检验滚动定位、翻页拆段与长段内的句子跟随。
final SampleParagraphSpec _cliffRoadParagraph = SampleParagraphSpec(
  source: SampleSideSpec.withAudio([
    'The road to the lighthouse climbed along the cliff, and the fog '
        'climbed with it.',
    'Lin Wan could hear the sea long before she could see it, a slow '
        'breathing somewhere below her left hand.',
    'Every few steps a wooden post rose out of the grey, each one painted '
        'with a white ring so that walkers would not lose the edge.',
    'She counted them at first, the way she used to count streetlamps from '
        'the back seat of her father’s car.',
    'Somewhere after forty she gave up, because the posts kept coming and '
        'the numbers no longer meant anything.',
    'The path narrowed until it was barely wider than her shoulders, and '
        'the grass on both sides was bent flat by years of the same wind.',
    'The suitcase grew heavier, and she began to wonder what she had packed '
        'that deserved to be carried this far.',
    'Three sweaters, a kettle, a box of pencils, and a dictionary she had '
        'not opened since school.',
    'None of it seemed like the luggage of someone who planned to stay.',
    'Yet she had sold her desk before leaving, and returned the key to her '
        'landlady with a small bow.',
    'She remembered the ticket seller at the ferry office, who had looked '
        'at her destination twice and then at her shoes.',
    '“Nobody goes up there for pleasure,” he had said, sliding the change '
        'across the counter one coin at a time.',
    'She had thanked him anyway, since it was the first thing anyone had '
        'said to her all day.',
    'Now, with salt drying on her lips, she understood that he had not been '
        'warning her so much as wishing her luck.',
    'A gull appeared beside her, hanging in the wind at the height of her '
        'shoulder, and studied her with one yellow eye.',
    'It did not seem impressed.',
    'Then the wind turned, the bird slid away, and for a moment the fog '
        'tore open like wet paper.',
    'In the gap stood the lighthouse, shorter than she had imagined and far '
        'more stubborn.',
    'Its white walls were streaked with rust below every window, as if the '
        'building had been crying for years and nobody had thought to wipe '
        'its face.',
    'A blue door faced the path, and beside the door hung a brass bell with '
        'a rope worn smooth by other hands.',
    'Far below, a wave broke against the rocks with the dull sound of a '
        'door being closed in another room.',
    'She set the suitcase down and discovered that her fingers would not '
        'straighten.',
    'She laughed at them, quietly, because there was no one to be '
        'embarrassed in front of.',
    'The fog closed again, and the lighthouse vanished so completely that '
        'she might have invented it.',
    'But the bell was still there, an arm’s length away, cold and real when '
        'she touched it.',
    'She thought of the letter in her pocket, of the careful handwriting '
        'that leaned to the right like grass in a steady wind.',
    'She thought of how strange it was to be expected by a stranger.',
    'Then, before she could change her mind, she took hold of the rope and '
        'rang the bell twice.',
    'The sound went out over the water and did not come back.',
    'Inside the tower, slowly, somebody began to come down the stairs.',
  ]),
  translation: SampleSideSpec.withAudio([
    '通往灯塔的路沿着崖壁向上爬，雾也跟着一起往上爬。',
    '林晚还没看见海，就先听见了它，像是有什么在她左手下方缓慢地呼吸。',
    '每走几步，灰白里就冒出一根木桩，桩上刷着一圈白漆，好让赶路的人不至于找不到崖边。',
    '起初她一根一根地数，就像小时候坐在父亲车子的后座上数路灯那样。',
    '数过四十以后她放弃了，因为木桩没完没了，数字也早就失去了意义。',
    '小路越走越窄，最后只比她的肩膀宽出一点，两旁的草被同一阵风吹了许多年，全都伏倒在地上。',
    '箱子越来越沉，她开始琢磨，自己到底装了些什么，值得被拎到这么远的地方来。',
    '三件毛衣，一只水壶，一盒铅笔，还有一本毕业以后再没翻开过的词典。',
    '怎么看，这都不像是一个打算长住的人会带的行李。',
    '可她临走前已经把书桌卖掉了，还微微鞠了一躬，把钥匙交还给了房东太太。',
    '她想起渡口售票处的那个人，他把她要去的地名看了两遍，又低头看了看她的鞋。',
    '“没有人是为了散心才上那儿去的。”他一边说，一边把找回的零钱一枚一枚推过柜台。',
    '她还是向他道了谢，毕竟那是这一整天里头一回有人同她说话。',
    '此刻盐粒在她的嘴唇上慢慢变干，她才明白，那与其说是警告，不如说是在祝她好运。',
    '一只海鸥出现在她身旁，悬在与她肩膀齐平的风里，用一只黄眼睛打量着她。',
    '看样子它并不怎么满意。',
    '接着风向一转，那只鸟滑走了，雾在一瞬间像湿纸一样被撕开。',
    '裂口里立着那座灯塔，比她想象的要矮，却也倔强得多。',
    '每一扇窗子下面的白墙上都挂着锈迹，仿佛这座房子哭了许多年，却始终没有人想起替它擦一擦脸。',
    '一扇蓝色的门正对着小路，门边挂着一口铜铃，铃绳早被别人的手磨得发亮。',
    '远远的崖底，一道浪撞碎在礁石上，闷闷的一声，像是隔壁房间里有人关上了门。',
    '她把箱子放下，这才发现手指已经伸不直了。',
    '她对着自己的手指轻轻笑了一声，反正这里也没有谁会让她觉得难为情。',
    '雾重新合拢，灯塔消失得干干净净，简直像是她自己编出来的。',
    '可那口铃还在，就在一臂之外，伸手去摸，又凉又真切。',
    '她想起口袋里的那封信，想起那一笔一画都很用心的字迹，朝右边倾斜着，像被风一直吹着的草。',
    '她又想，被一个陌生人盼着到来，是多么奇怪的一件事。',
    '然后，趁自己还来不及改变主意，她抓住铃绳，摇了两下。',
    '铃声朝海面上荡开去，没有再回来。',
    '塔里，有人慢慢地，开始走下楼梯。',
  ]),
);

final SampleChapterSpec _keeperLedgerChapter = SampleChapterSpec(
  title: '第二章 守灯人的账本',
  blocks: [
    SampleParagraphSpec(
      source: SampleSideSpec.withAudio([
        'The keeper’s ledger lay open on the kitchen table.',
        'Its last entry was dated nine days ago.',
      ]),
    ),
    SampleParagraphSpec(
      source: const SampleSideSpec([
        SampleSentence(
          'Her uncle wrote down everything: the hour the lamp was lit, the '
          'direction of the wind, the names of the boats that passed.',
        ),
        SampleSentence(
          'On some pages he had also drawn the clouds.',
          hasAudio: false,
        ),
        SampleSentence(
          'Lin Wan turned the pages slowly, as if they might wake him.',
        ),
      ]),
      translation: SampleSideSpec.withoutAudio([
        '叔父把什么都记了下来：点灯的时刻，风的方向，还有每一艘经过的船的名字。',
        '有几页上，他还画了云。',
        '林晚一页一页慢慢地翻，仿佛翻快了就会把他吵醒。',
      ]),
    ),
    SampleParagraphSpec(
      translation: SampleSideSpec.withoutAudio([
        '（译者按：账本原件中此处有半页被水渍洇开，字迹已无法辨认。）',
      ]),
    ),
    const SampleIllustrationSpec(imageFileName: 'keeper_ledger.png'),
    SampleParagraphSpec(
      source: SampleSideSpec.withAudio([
        'At the bottom of the last page there was a single line, written '
            'more heavily than the rest.',
        '“If you are reading this, the lamp is yours now.”',
      ]),
      translation: SampleSideSpec.withoutAudio([
        '最后一页的页脚只有一行字，笔迹比别处都重。',
        '“如果你正在读这一行，那盏灯现在归你了。”',
      ]),
    ),
  ],
);

final SampleChapterSpec _autumnTideChapter = SampleChapterSpec(
  title: '第三章 秋潮',
  blocks: [
    SampleParagraphSpec(
      source: SampleSideSpec.withoutAudio([
        'The autumn tide came in three nights later.',
        'Lin Wan climbed the stairs with a box of matches and her uncle’s '
            'ledger under her arm.',
      ]),
      translation: SampleSideSpec.withoutAudio([
        '三天后的夜里，秋潮来了。',
        '林晚夹着一盒火柴和叔父的账本，走上了楼梯。',
      ]),
    ),
    SampleParagraphSpec(
      source: SampleSideSpec.withoutSentenceData([
        'She lit the lamp at six minutes past seven and wrote the time down.',
        'Then, after thinking for a while, she drew a cloud beside it.',
      ]),
      translation: SampleSideSpec.withoutSentenceData([
        '七点零六分，她点亮了灯，把时刻记了下来。',
        '想了一会儿，她又在旁边画了一朵云。',
      ]),
    ),
    SampleParagraphSpec(
      source: SampleSideSpec.withoutAudio([
        'Out on the dark water, a boat she could not name answered with a '
            'single light.',
      ]),
      translation: SampleSideSpec.withoutAudio([
        '黑沉沉的海面上，一艘她叫不出名字的船，用一点灯光作了回答。',
      ]),
    ),
  ],
);
