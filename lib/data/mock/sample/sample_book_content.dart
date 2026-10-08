/// 示例书的正文。全部为本项目原创的演示文字，原文为日语、译文为中文。
/// 文字都是不含任何标记的显示文字，样式另用「短语 + 样式」标注。
///
/// 语音模拟真实使用情形：只有对白带语音，旁白没有。
/// 三章合起来覆盖界面需要应对的各种数据形态：
/// - 第一章：一级与二级标题、粗体、斜体、粗斜体叠加、跨越句子边界的样式、
///   带说明的插图、超过一屏的长段落、分隔线；
///   语音有「只有译文带」「两面都带」「两面都不带」以及同段内混排；
///   还有原文一面没有句级切分的段落。
/// - 第二章：三级标题、删除线、引用段、不带说明的插图；
///   语音有「只有原文带」「两面都带」；有只有原文、只有译文的段落；
///   有一处句间间隙（问号后的全角空格不属于任何句子）。
/// - 第三章：行内代码、含 emoji 的文字（其后的偏移量要按 UTF-16 码元计）、分隔线；
///   有两面都没有句级切分的段落。
library;

import '../../../domain/domain.dart';
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
      style: ParagraphStyle.heading1,
      source: SampleSideSpec.withoutSentenceData(['第一部　到着']),
      translation: SampleSideSpec.narration(['卷一 抵达']),
    ),
    SampleParagraphSpec(
      source: SampleSideSpec.narration(
        [
          '連絡船は一時間遅れて霧の港に着いた。',
          '林晩はトランクを一つ提げて桟橋に降りた。',
          'ポケットには、何度も読み返した手紙が入っている。',
          '迎えに来た人は誰もいなかった。',
        ],
        styledPhrases: const [
          SampleStyledPhrase('誰もいなかった', {InlineStyle.bold}),
        ],
      ),
      translation: SampleSideSpec.narration(
        ['渡船晚了一个钟头才靠上雾港。', '林晚提着一只箱子走上栈桥，口袋里揣着那封读过太多遍的信。', '没有人来接她。'],
        styledPhrases: const [
          SampleStyledPhrase('没有人', {InlineStyle.bold}),
        ],
      ),
    ),
    const SampleIllustrationSpec(
      imageFileName: 'fog_harbor_pier.png',
      caption: '雾中的栈桥',
    ),
    SampleParagraphSpec(
      source: SampleSideSpec.narration([
        '切符売り場の男は、行き先を二度見てから彼女の靴に目を落とした。',
        '「あそこへ遊びで行く人はいませんよ」',
        '彼はそう言って、お釣りを一枚ずつカウンターに滑らせた。',
        '「それでも、行くんです」',
      ]),
      translation: const SampleSideSpec([
        SampleSentence('售票处的男人把她要去的地名看了两遍，又低头看了看她的鞋。'),
        SampleSentence.voiced('“没有人是为了散心才上那儿去的。”'),
        SampleSentence('他一边说，一边把找回的零钱一枚一枚推过柜台。'),
        SampleSentence.voiced('“可我还是要去。”'),
      ]),
    ),
    const SampleParagraphSpec(
      source: SampleSideSpec(
        [
          SampleSentence('手紙の差出人は、一度も会ったことのない叔父だった。'),
          SampleSentence.voiced('「秋の大潮の前に来なさい」'),
          SampleSentence.voiced('「灯台には灯台守が要る。私に残された朝は、もう多くない」'),
        ],
        styledPhrases: [
          SampleStyledPhrase('秋の大潮の前に来なさい', {InlineStyle.italic}),
          SampleStyledPhrase('灯台守', {InlineStyle.bold, InlineStyle.italic}),
        ],
      ),
      translation: SampleSideSpec(
        [
          SampleSentence('信的落款是一位她从未见过的叔父。'),
          SampleSentence.voiced('“赶在秋潮之前来。”'),
          SampleSentence.voiced('“灯塔需要一个守灯人，而我剩下的清晨不多了。”'),
        ],
        styledPhrases: [
          SampleStyledPhrase('赶在秋潮之前来', {InlineStyle.italic}),
          SampleStyledPhrase('守灯人', {InlineStyle.bold, InlineStyle.italic}),
        ],
      ),
    ),
    SampleParagraphSpec(
      style: ParagraphStyle.heading2,
      source: SampleSideSpec.withoutSentenceData(['崖の道']),
      translation: SampleSideSpec.withoutSentenceData(['崖边的路']),
    ),
    _cliffRoadParagraph,
    const SampleDividerSpec(),
    SampleParagraphSpec(
      source: SampleSideSpec.withoutSentenceData([
        '足音は青い扉の向こうで止まった。',
        '「……どなたかな」',
      ]),
      translation: const SampleSideSpec([
        SampleSentence('脚步声在蓝色的门后停住了。'),
        SampleSentence.voiced('“……是哪一位？”'),
      ]),
    ),
  ],
);

/// 超过一屏的长段落，用来检验段内定位、翻页拆段，以及长段落里的点句。
/// 通篇是旁白，只有中间一句自言自语带语音。
const SampleParagraphSpec _cliffRoadParagraph = SampleParagraphSpec(
  source: SampleSideSpec(
    [
      SampleSentence('灯台へ続く道は崖に沿って登っていき、霧も一緒に登ってきた。'),
      SampleSentence('海は見えるよりずっと先に聞こえた。'),
      SampleSentence('左手の下のどこかで、何かがゆっくりと息をしているようだった。'),
      SampleSentence('数歩ごとに灰色の中から木の杭が現れ、どの杭にも白い輪が塗ってあった。'),
      SampleSentence('歩く人が崖の縁を見失わないためだ。'),
      SampleSentence('はじめのうち、彼女は一本ずつ数えた。'),
      SampleSentence('子どものころ、父の車の後部座席から街灯を数えたのと同じやり方で。'),
      SampleSentence('四十を過ぎたあたりで数えるのをやめた。'),
      SampleSentence('杭はいつまでも続き、数字にはもう何の意味もなかった。'),
      SampleSentence('道はしだいに狭くなり、ついには肩幅よりわずかに広いだけになった。'),
      SampleSentence('両側の草は、長年同じ風に吹かれて地面に伏せていた。'),
      SampleSentence('トランクはだんだん重くなった。'),
      SampleSentence('こんな遠くまで運ぶ値打ちのあるものを、自分はいったい何を詰めてきたのだろう、と彼女は考えはじめた。'),
      SampleSentence('セーターが三枚、やかんが一つ、鉛筆が一箱、それに卒業してから一度も開いていない辞書が一冊。'),
      SampleSentence('どう見ても、長く住むつもりの人の荷物ではなかった。'),
      SampleSentence('けれども出発の前に机は売ってしまったし、鍵は小さくお辞儀をして大家さんに返してきた。'),
      SampleSentence('一羽のカモメが隣に現れ、肩の高さで風に浮かんだまま、黄色い片目で彼女を値踏みした。'),
      SampleSentence('あまり感心した様子ではなかった。'),
      SampleSentence('やがて風向きが変わり、鳥は滑るように離れていった。'),
      SampleSentence('その一瞬、霧が濡れた紙のように裂けた。'),
      SampleSentence('裂け目の中に灯台が立っていた。'),
      SampleSentence('思っていたより背が低く、思っていたよりずっと頑固そうだった。'),
      SampleSentence('どの窓の下にも白い壁に錆の筋が垂れていた。'),
      SampleSentence('まるで建物が何年も泣きつづけ、誰も顔を拭いてやろうと思わなかったかのように。'),
      SampleSentence('青い扉が小道に面していて、その脇に真鍮の鐘が下がっていた。'),
      SampleSentence('鐘の綱は、ほかの誰かの手ですっかり磨り減っていた。'),
      SampleSentence('はるか崖の下で、波が岩に砕けた。'),
      SampleSentence('隣の部屋で誰かが扉を閉めたような、鈍い音だった。'),
      SampleSentence('トランクを下ろして、彼女ははじめて指が伸びなくなっていることに気づいた。'),
      SampleSentence('自分の指に向かって、彼女は小さく笑った。'),
      SampleSentence('ここには、恥ずかしがる相手など誰もいないのだから。'),
      SampleSentence.voiced('「着いた」'),
      SampleSentence('と、彼女は自分に言い聞かせた。'),
      SampleSentence('霧がふたたび閉じ、灯台は跡形もなく消えた。'),
      SampleSentence('自分でこしらえた幻だったのかと思うほどだった。'),
      SampleSentence('それでも鐘はまだそこにあった。'),
      SampleSentence('腕を伸ばせば届くところに。'),
      SampleSentence('触れてみると、冷たくて、確かだった。'),
      SampleSentence('彼女はポケットの手紙のことを考えた。'),
      SampleSentence('一画ずつ丁寧に書かれ、絶えず風に吹かれる草のように右へ傾いた、あの文字のことを。'),
      SampleSentence('見知らぬ人に待たれているというのは、なんと奇妙なことだろう、とも思った。'),
      SampleSentence('それから、気が変わってしまう前に、彼女は綱をつかんで鐘を二度鳴らした。'),
      SampleSentence('音は海の上へ広がっていき、戻ってはこなかった。'),
      SampleSentence('塔の中で、誰かがゆっくりと階段を下りはじめた。'),
    ],
    styledPhrases: [_crossSentenceSourcePhrase],
  ),
  translation: SampleSideSpec(
    [
      SampleSentence('通往灯塔的路沿着崖壁向上爬，雾也跟着一起往上爬。'),
      SampleSentence('林晚还没看见海，就先听见了它，像是有什么在她左手下方缓慢地呼吸。'),
      SampleSentence('每走几步，灰白里就冒出一根木桩，桩上刷着一圈白漆，好让赶路的人不至于找不到崖边。'),
      SampleSentence('起初她一根一根地数，就像小时候坐在父亲车子的后座上数路灯那样。'),
      SampleSentence('数过四十以后她放弃了，因为木桩没完没了，数字也早就失去了意义。'),
      SampleSentence('小路越走越窄，最后只比她的肩膀宽出一点，两旁的草被同一阵风吹了许多年，全都伏倒在地上。'),
      SampleSentence('箱子越来越沉，她开始琢磨，自己到底装了些什么，值得被拎到这么远的地方来。'),
      SampleSentence('三件毛衣，一只水壶，一盒铅笔，还有一本毕业以后再没翻开过的词典。'),
      SampleSentence('怎么看，这都不像是一个打算长住的人会带的行李。'),
      SampleSentence('可她临走前已经把书桌卖掉了，还微微鞠了一躬，把钥匙交还给了房东太太。'),
      SampleSentence('一只海鸥出现在她身旁，悬在与她肩膀齐平的风里，用一只黄眼睛打量着她。'),
      SampleSentence('看样子它并不怎么满意。'),
      SampleSentence('接着风向一转，那只鸟滑走了，雾在一瞬间像湿纸一样被撕开。'),
      SampleSentence('裂口里立着那座灯塔，比她想象的要矮，却也倔强得多。'),
      SampleSentence('每一扇窗子下面的白墙上都挂着锈迹，仿佛这座房子哭了许多年，却始终没有人想起替它擦一擦脸。'),
      SampleSentence('一扇蓝色的门正对着小路，门边挂着一口铜铃，铃绳早被别人的手磨得发亮。'),
      SampleSentence('远远的崖底，一道浪撞碎在礁石上，闷闷的一声，像是隔壁房间里有人关上了门。'),
      SampleSentence('她把箱子放下，这才发现手指已经伸不直了。'),
      SampleSentence('她对着自己的手指轻轻笑了一声，反正这里也没有谁会让她觉得难为情。'),
      SampleSentence.voiced('“到了。”'),
      SampleSentence('她这样对自己说。'),
      SampleSentence('雾重新合拢，灯塔消失得干干净净，简直像是她自己编出来的。'),
      SampleSentence('可那口铃还在，就在一臂之外，伸手去摸，又凉又真切。'),
      SampleSentence('她想起口袋里的那封信，想起那一笔一画都很用心的字迹，朝右边倾斜着，像被风一直吹着的草。'),
      SampleSentence('她又想，被一个陌生人盼着到来，是多么奇怪的一件事。'),
      SampleSentence('然后，趁自己还来不及改变主意，她抓住铃绳，摇了两下。'),
      SampleSentence('铃声朝海面上荡开去，没有再回来。'),
      SampleSentence('塔里，有人慢慢地，开始走下楼梯。'),
    ],
    styledPhrases: [_crossSentenceTranslationPhrase],
  ),
);

/// 这两处样式故意从倒数第二句的句尾延伸到最后一句的开头，
/// 用来检验「样式区间跨越句子边界」时高亮与样式的叠加。
const SampleStyledPhrase _crossSentenceSourcePhrase = SampleStyledPhrase(
  '戻ってはこなかった。塔の中で、誰かがゆっくりと',
  {InlineStyle.italic},
);
const SampleStyledPhrase _crossSentenceTranslationPhrase = SampleStyledPhrase(
  '没有再回来。塔里，有人慢慢地',
  {InlineStyle.italic},
);

final SampleChapterSpec _keeperLedgerChapter = SampleChapterSpec(
  title: '第二章 守灯人的账本',
  blocks: [
    SampleParagraphSpec(
      style: ParagraphStyle.heading3,
      source: SampleSideSpec.withoutSentenceData(['最後の一週間の記録']),
      translation: SampleSideSpec.narration(['最后一周的记录']),
    ),
    const SampleParagraphSpec(
      source: SampleSideSpec([
        SampleSentence('扉を開けたのは、叔父ではなかった。'),
        // 问号后的全角空格是日文排版习惯，它在正文里，但不属于前后任何一句。
        SampleSentence.voiced('「着いたのかい？', gapAfter: '　'),
        SampleSentence.voiced('よく来たね」'),
        SampleSentence('隣の家の老婦人は、そう言って鍵束を差し出した。'),
      ]),
      translation: SampleSideSpec([
        SampleSentence('开门的不是叔父。'),
        SampleSentence.voiced('“到了啊？来得好。”'),
        SampleSentence('隔壁的老妇人说着，把一串钥匙递了过来。'),
      ]),
    ),
    SampleParagraphSpec(
      source: const SampleSideSpec([
        SampleSentence.voiced('「叔父さんは九日前に亡くなったよ」'),
        SampleSentence('老婦人は静かに言った。'),
      ]),
      translation: SampleSideSpec.narration(['“你叔父九天前过世了。”', '老妇人平静地说。']),
    ),
    SampleParagraphSpec(
      source: SampleSideSpec.narration(
        [
          '台所の机には、灯台守の帳簿が開いたまま置かれていた。',
          '叔父は何もかも書きとめていた。',
          '灯をともした時刻、風の向き、通り過ぎた船の名前。',
          'ところどころに、雲の絵まで描いてあった。',
        ],
        styledPhrases: const [
          SampleStyledPhrase('風の向き', {InlineStyle.strikethrough}),
        ],
      ),
      translation: SampleSideSpec.narration(
        [
          '厨房的桌上摊着守灯人的账本。',
          '叔父把什么都记了下来：点灯的时刻，风的方向，还有每一艘经过的船的名字。',
          '有几页上，他还画了云。',
        ],
        styledPhrases: const [
          SampleStyledPhrase('风的方向', {InlineStyle.strikethrough}),
        ],
      ),
    ),
    SampleParagraphSpec(
      translation: SampleSideSpec.narration(['（译者按：账本原件中此处有半页被水渍洇开，字迹已无法辨认。）']),
    ),
    const SampleIllustrationSpec(imageFileName: 'keeper_ledger.png'),
    SampleParagraphSpec(
      source: SampleSideSpec.narration(['帳簿の最後の記入は、九日前の日付だった。']),
    ),
    SampleParagraphSpec(
      source: SampleSideSpec.narration([
        '最後のページのいちばん下に、ほかよりも強い筆圧で、一行だけ書いてあった。',
      ]),
      translation: SampleSideSpec.narration(['最后一页的页脚只有一行字，笔迹比别处都重。']),
    ),
    SampleParagraphSpec(
      style: ParagraphStyle.quote,
      source: SampleSideSpec.narration(['これを読んでいるなら、あの灯はもうお前のものだ。']),
      translation: SampleSideSpec.narration(['如果你正在读这一行，那盏灯现在归你了。']),
    ),
  ],
);

final SampleChapterSpec _autumnTideChapter = SampleChapterSpec(
  title: '第三章 秋潮',
  blocks: [
    SampleParagraphSpec(
      source: SampleSideSpec.narration([
        '三日後の夜、秋の大潮が来た。',
        '林晩はマッチの箱と叔父の帳簿を脇に抱えて、階段を上った。',
      ]),
      translation: SampleSideSpec.narration([
        '三天后的夜里，秋潮来了。',
        '林晚夹着一盒火柴和叔父的账本，走上了楼梯。',
      ]),
    ),
    SampleParagraphSpec(
      source: SampleSideSpec.withoutSentenceData(
        ['19:06、彼女は灯をともし、その時刻を書きとめた。', '少し考えてから、その横に雲を一つ描いた。'],
        styledPhrases: const [
          SampleStyledPhrase('19:06', {InlineStyle.code}),
        ],
      ),
      translation: SampleSideSpec.withoutSentenceData(
        ['19:06，她点亮了灯，把时刻记了下来。', '想了一会儿，她又在旁边画了一朵云。'],
        styledPhrases: const [
          SampleStyledPhrase('19:06', {InlineStyle.code}),
        ],
      ),
    ),
    _messageParagraph,
    const SampleDividerSpec(),
    SampleParagraphSpec(
      source: SampleSideSpec.narration(['暗い海の上で、名前も知らない船が、一つの灯りで返事をした。']),
      translation: SampleSideSpec.narration(['黑沉沉的海面上，一艘她叫不出名字的船，用一点灯光作了回答。']),
    ),
  ],
);

/// 含 emoji 的段落。emoji 在 UTF-16 里占两个码元，
/// 排在它后面的样式区间与句子区间都要把这一点算进去才不会错位。
const SampleParagraphSpec _messageParagraph = SampleParagraphSpec(
  source: SampleSideSpec(
    [
      SampleSentence('それから母に短いメッセージを送った。'),
      SampleSentence('「灯台に着いたよ🌊　今夜から私が灯をともします」'),
      SampleSentence('返事はすぐに来た。'),
      SampleSentence('「風邪をひかないようにね」'),
    ],
    styledPhrases: [
      SampleStyledPhrase('今夜から', {InlineStyle.bold}),
    ],
  ),
  translation: SampleSideSpec(
    [
      SampleSentence('然后她给母亲发了一条短短的消息。'),
      SampleSentence.voiced('“我到灯塔了🌊 今晚起由我来点灯。”'),
      SampleSentence('回信很快就来了。'),
      SampleSentence.voiced('“别着凉。”'),
    ],
    styledPhrases: [
      SampleStyledPhrase('今晚起', {InlineStyle.bold}),
    ],
  ),
);
