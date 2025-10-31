import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/ai/ai_bloc.dart';
import '../../data/services/ai_service.dart';

/// AI Utilities Panel for note editor
class AIUtilitiesPanel extends StatelessWidget {
  final String? ocrText;
  final String? aiSummary;
  final List<Flashcard>? flashcards;

  const AIUtilitiesPanel({
    super.key,
    this.ocrText,
    this.aiSummary,
    this.flashcards,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AIBloc, AIState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Tabs
              DefaultTabController(
                length: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'OCR'),
                        Tab(text: 'Summary'),
                        Tab(text: 'Flashcards'),
                      ],
                    ),
                    SizedBox(
                      height: 300,
                      child: TabBarView(
                        children: [
                          _buildOCRTab(context, state),
                          _buildSummaryTab(context, state),
                          _buildFlashcardsTab(context, state),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOCRTab(BuildContext context, AIState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state is AIInProgress && state.operation == 'OCR')
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (state is OCRSuccess)
            Text(
              state.result.text,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else if (ocrText != null)
            Text(
              ocrText!,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No OCR text available. Process image to extract text.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(BuildContext context, AIState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state is AIInProgress && state.operation == 'Summary')
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (state is SummarySuccess)
            Text(
              state.result.summary,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else if (aiSummary != null)
            Text(
              aiSummary!,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Generate summary from OCR text or note content.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFlashcardsTab(BuildContext context, AIState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state is AIInProgress && state.operation == 'Flashcards')
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (state is FlashcardsSuccess)
            ...state.flashcards.map((card) => _buildFlashcardCard(context, card))
          else if (flashcards != null && flashcards!.isNotEmpty)
            ...flashcards!.map((card) => _buildFlashcardCard(context, card))
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Generate flashcards from note content.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFlashcardCard(BuildContext context, Flashcard card) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          card.question,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              card.answer,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

